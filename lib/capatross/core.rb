# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'json'
module Capatross
  class TemplateError < NameError
  end

  class Core
    attr_accessor :settings

    def initialize
      @settings = Options.new
      @settings.load!
      @deploydata = {:appkey => @settings.appkey}
    end

    def local_deployer
      ENV['USER']
    end

    def git_deployer
      if(gitutils)
        gitutils.user_name
      else
        nil
      end
    end

    def post_deploydata
      begin
        response = RestClient.post("#{settings.albatross_uri}#{settings.albatross_deploy_path}",
                        deploydata.to_json,
                        :content_type => :json, :accept => :json)
      rescue=> e
        response = e.response
      end

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

    def gitutils
      @gitutils ||= GitUtils.new('.')
    end

    def deployer
      if(!(deployer = git_deployer))
        deployer = local_deployer
      end
      deployer
    end

    def capatross_id
      if(@capatross_id.nil?)
        randval = rand
        @capatross_id = Digest::SHA1.hexdigest(settings.appkey+Time.now.to_s+randval.to_s)[8..16]
      end
      @capatross_id
    end

    def merge_deploydata(hash)
      @deploydata.merge!(hash)
    end

    def deploydata
      if(@deploydata[:capatross_id].nil?)
        @deploydata[:capatross_id] = capatross_id
      end
      @deploydata
    end

    def write_deploydata
      outputdir = "./capatross_logs"
      outputfile = File.join(outputdir,"#{deploydata[:capatross_id]}.json")
      FileUtils.mkdir_p(outputdir)
      File.open(outputfile, 'w') {|f| f.write(deploydata.to_json) }
      # also write to "application_latest"
      if(deploydata[:application])
        latest_outputfile = File.join(outputdir,"#{deploydata[:application]}_latest.json")
        File.open(latest_outputfile, 'w') {|f| f.write(deploydata.to_json) }
      end
      outputfile
    end


    def whereto(capistrano_namespace)
      default_value =  ENV['SERVER'] || 'production'
      capistrano_namespace.fetch(:stage,default_value)
    end

  end
end
