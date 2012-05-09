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
require 'httparty'
module Capatross
  class CLI < Thor
    include Thor::Actions

    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end
    
    no_tasks do
      
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
            append_file(gitignore_file,"/config/capatross.local.yml\n")
          end
          
          # deploylogs
          if(!(File.read(gitignore_file) =~ %r{capatross_logs}))
            append_file(gitignore_file,"/capatross_logs\n")
          end
                  
        end
      end
      
      def add_capatross_to_deploy
        cap_deploy_script = './config/deploy.rb'
        if(File.exists?(cap_deploy_script))
          if(!(File.read(cap_deploy_script) =~ %r{require ['|"]capatross["|']}))
            prepend_file(cap_deploy_script,"require 'capatross'\n")
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
        result = HTTParty.post("#{settings.albatross_uri}#{settings.albatross_deploy_path}",
                                :body => logdata,
                                :headers => { 'ContentType' => 'application/json' })
                              
        result
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
                        
      if(post_to_deploy_server(logdata))
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
          if(result.response.code == '200')
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
    # 
    # desc "prune", "prune old deploy logs"
    # def prune
    # end
              
  end
  
end
