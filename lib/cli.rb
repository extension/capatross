# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'thor'
require 'yaml'
require 'json'
require 'capatross/version'
require 'capatross/options'
require 'capatross/deep_merge' unless defined?(DeepMerge)
require 'rest-client'
require 'net/scp'
require 'mathn'
require 'pp'

module Capatross
  class CLI < Thor
    include Thor::Actions

    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end

    no_tasks do

      def load_rails(environment)
        if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
          ENV["RAILS_ENV"] = environment
        end

        # there are differences in the require semantics between Ruby 1.8 and Ruby 1.9
        if(RUBY_VERSION =~ %r{1\.9})
          loadrails = "./config/environment"
        elsif(RUBY_VERSION =~ %r{1\.8})
          loadrails = "config/environment"
        else
          puts "Unknown ruby version #{RUBY_VERSION}"
          exit(1)
        end

        begin
          require loadrails
        rescue LoadError
          puts 'capatross uses rails for certain features, it appears you are not at the root of a rails application, exiting...'
          exit(1)
        end
      end

      def logsdir
        './capatross_logs'
      end

      def copy_configs
        # campout.yml
        destination = "./config/capatross.yml"
        if(!File.exists?(destination))
          copy_file('templates/capatross.yml',destination)
        end
      end

      def add_local_to_gitignore
        gitignore_file = './.gitignore'
        if(File.exists?(gitignore_file))
          # local configuration
          if(!(File.read(gitignore_file) =~ %r{config/capatross.local.yml}))
            append_file(gitignore_file,"\n# added by capatross generate_config\n/config/capatross.local.yml\n")
          end

          # deploylogs
          if(!(File.read(gitignore_file) =~ %r{capatross_logs}))
            append_file(gitignore_file,"\n# added by capatross generate_config\n/capatross_logs\n")
          end

        end
      end

      def add_capatross_to_deploy
        cap_deploy_script = './config/deploy.rb'
        if(File.exists?(cap_deploy_script))
          if(!(File.read(cap_deploy_script) =~ %r{require ['|"]capatross["|']}))
            prepend_file(cap_deploy_script,"\n# added by capatross generate_config\nrequire 'capatross'\n")
          end
        end
      end

      def deploy_logs(dump_log_output=true)
        deploy_logs = []
        # loop through the files
        Dir.glob(File.join(logsdir,'*.json')).sort.each do |logfile|
          logdata = JSON.parse(File.read(logfile))
          if(dump_log_output)
            logdata.delete('deploy_log')
          end
          deploy_logs << logdata
        end

        deploy_logs
      end

      def settings
        if(@settings.nil?)
          @settings = Capatross::Options.new
          @settings.load!
        end

        @settings
      end

      def post_to_deploy_server(logdata)
        # indicate that this is coming from the cli
        logdata['from_cli'] = true
        begin
          RestClient.post("#{settings.albatross_uri}#{settings.albatross_deploy_path}",
                          logdata.to_json,
                          :content_type => :json, :accept => :json)
        rescue=> e
          e.response
        end
      end

      def check_post_result(response)
        if(!response.code == 200)
          return false
        else
          begin
            parsed_response = JSON.parse(response)
            if(parsed_response['success'])
              return true
            else
              return false
            end
          rescue
            return false
          end
        end
      end

      # from:
      # http://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
      def show_wait_spinner(fps=10)
        chars = %w[| / - \\]
        delay = 1.0/fps
        iter = 0
        spinner = Thread.new do
          while iter do  # Keep spinning until told otherwise
            print chars[(iter+=1) % chars.length]
            sleep delay
            print "\b"
          end
        end
        yield.tap{       # After yielding to the block, save the return value
          iter = false   # Tell the thread to exit, cleaning up after itself…
          spinner.join   # …and wait for it to do so.
        }                # Use the block's return value as the method's
      end

      # code from: https://github.com/ripienaar/mysql-dump-split
      def humanize_bytes(bytes)
        if(bytes != 0)
          units = %w{B KB MB GB TB}
          e = (Math.log(bytes)/Math.log(1024)).floor
          s = "%.1f"%(bytes.to_f/1024**e)
          s.sub(/\.?0*$/,units[e])
        end
      end

      def percentify(number)
        s = "%.0f\%"%(number*100)
      end

    end


    desc "about", "about capatross"
    def about
      puts "Capatross Version #{Capatross::VERSION}: Post logs from a capistrano deploy to the deployment server, as well as a custom deploy-tracking application."
    end

    desc "generate_config", "generate capatross configuration files"
    def generate_config
      copy_configs
      add_local_to_gitignore
      add_capatross_to_deploy
    end

    desc "list", "list local deploys"
    def list
      if(!File.exists?(logsdir))
         say("Error: Capatross log directory (#{logsdir}) not present", :red)
      end

      deploy_logs.sort_by{|log| log['start']}.each do |log|
        if(log['success'])
          message = "#{log['capatross_id']} : Revision: #{log['deployed_revision']} deployed at #{log['start'].to_s} to #{log['location']}"
        else
          message = "#{log['capatross_id']} : Deploy failed at #{log['start'].to_s} to #{log['location']}"
        end

        if(log['finish_posted'])
          message += ' (posted)'
          say(message)
        else
          message += ' (not posted)'
          say(message,:yellow)
        end
      end
    end

    desc "post", "post or repost the logdata from the specified local deploy"
    method_option :log, :aliases => '-l', :type => :string, :required => true, :desc => "The capatross deploy id to post/repost (use 'list' to show known deploys)"
    def post
      logfile = "./capatross_logs/#{options[:log]}.json"
      if(!File.exists?(logfile))
         say("Error: The specified capatross log (#{options[:log]}) was not found", :red)
      end
      logdata = JSON.parse(File.read(logfile))

      result = post_to_deploy_server(logdata)
      if(check_post_result(result))
        say("Log data posted to #{settings.albatross_uri}#{settings.albatross_deploy_path}")
        # update that we posted
        logdata['finish_posted'] = true
        File.open(logfile, 'w') {|f| f.write(logdata.to_json) }
      else
        say("Unable to post log data to #{settings.albatross_uri}#{settings.albatross_deploy_path} (Code: #{result.response.code })",:red)
      end
    end

    desc "sync", "post all unposted deploys"
    def sync
      if(!File.exists?(logsdir))
         say("Error: Capatross log directory (#{logsdir}) not present", :red)
      end

      deploy_logs(false).each do |log|
        if(!log['finish_posted'])
          result = post_to_deploy_server(log)
          if(check_post_result(result))
            say("#{log['capatross_id']} data posted to #{settings.albatross_uri}#{settings.albatross_deploy_path}")
            # update that we posted
            log['finish_posted'] = true
            logfile = File.join(logsdir,"#{log['capatross_id']}.json")
            File.open(logfile, 'w') {|f| f.write(log.to_json) }
          else
            say("Unable to post #{log['capatross_id']} data to #{settings.albatross_uri}#{settings.albatross_deploy_path} (Code: #{result.response.code })",:red)
          end
        end
      end
    end


    desc "getdata", "Download and replace my local database with new data"
    method_option :environment,:default => 'development', :aliases => "-e", :desc => "Rails environment"
    method_option :db,:default => 'development', :desc => "database.yml connection settings to use"
    def getdata
      load_rails(options[:environment])

      # download the file
      if(!settings.getdata.dbfiles.nil?)
        datafile = settings.getdata.dbfiles.send(options[:db])
        if(datafile.nil?)
          puts "No datafile specified for #{options[:db]}"
          exit(1)
        end
      elsif(!settings.getdata.dbfile.nil?)
        datafile = settings.getdata.dbfile
      else
        puts "Please set getdata.files['#{options[:db]}'] or getdata.file in the capatross settings"
        exit(1)
      end

      remotefile = "#{settings.getdata.path}/#{datafile}.gz"
      say "Downloading #{remotefile} from #{settings.getdata.host}..."
      Net::SSH.start(settings.getdata.host, settings.getdata.user, :port => 24) do |ssh|
        print "Downloaded "
        ssh.scp.download!(remotefile,"#{Rails.root.to_s}/tmp/#{datafile}.gz") do |ch, name, sent, total|
          print "\r"
          print "Downloaded "
          print "#{percentify(sent/total)} #{humanize_bytes(sent)} of #{humanize_bytes(total)}"
        end
        puts " ...done!"
      end

      dbsettings = ActiveRecord::Base.configurations[options[:db]]
      gunzip_command = "gunzip --force #{Rails.root.to_s}/tmp/#{datafile}.gz"
      pv_command = '/usr/local/bin/pv'
      db_import_command = "#{settings.getdata.mysqlbin} --default-character-set=utf8 -u#{dbsettings['username']} -p#{dbsettings['password']} #{dbsettings['database']} < #{Rails.root}/tmp/#{datafile}"

      # gunzip
      say "Unzipping #{Rails.root.to_s}/tmp/#{datafile}.gz..."
      run(gunzip_command, :verbose => false)

      # dump
      say "Dumping the tables from #{dbsettings['database']}... "
      ActiveRecord::Base.establish_connection(options[:db])
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Base.connection.execute("DROP table #{table};")
      end
      say "done!"


      # import
      say "Importing data into #{dbsettings['database']} (this might take a while)... "
      show_wait_spinner {
        run(db_import_command, :verbose => false)
      }
      puts " done!"
    end

    desc "showsettings", "Show settings"
    def showsettings
      pp settings.to_hash
    end


    #
    # desc "prune", "prune old deploy logs"
    # def prune
    # TODO
    # end

  end

end
