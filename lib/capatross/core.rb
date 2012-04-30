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
        @capatross_id = Digest::SHA1.hexdigest(settings.appkey+Time.now.to_s+randval.to_s)
      end
      @capatross_id
    end
    
    def merge_deploydata(hash)
      @deploydata.merge!(hash)
    end
    
    def write_deploydata
      if(@deploydata[:capatross_id].nil?)
        @deploydata[:capatross_id] = capatross_id
      end
      
      outputdir = "./capatross_logs"
      ouptputfile = File.join(outputdir,"#{@deploydata[:capatross_id]}.json")
      FileUtils.mkdir_p(outputdir)
      File.open(ouptputfile, 'w') {|f| f.write(@deploydata.to_json) }
      ouptputfile
    end
        
          
    def whereto(capistrano_namespace)
      default_value =  ENV['SERVER'] || 'production'
      capistrano_namespace.fetch(:stage,default_value)
    end
      
  end
end
