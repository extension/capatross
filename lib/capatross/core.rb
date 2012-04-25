# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module Capatross
  class TemplateError < NameError
  end
    
  class Core
    attr_accessor :settings
    
    def initialize
      @settings = Options.new
      @settings.load!
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
      
    def pre_announce(options = {})
      self.speak(erberize(settings.pre_deploy.message,'pre_deploy message',options[:binding]))
      @pre_announce_time = Time.now
    end
      
    def post_announce_success(options = {})
      message = erberize(settings.post_deploy_success.message,'post_deploy_success message',options[:binding])
      if(!settings.suppress_deploy_time and @pre_announce_time)
        message += " (#{time_period_to_s(Time.now - @pre_announce_time)})"
      end
        
      if(!settings.suppress_github_compare and gitutils)
        github_compare = true
        repository = options[:repository] || github_compare = false
        gitutils.repository = repository
        previous = options[:previous_revision] || github_compare = false
        latest = options[:latest_revision] || github_compare = false
      else
        github_compare = false
      end
      
      if(gitutils)
        gitutils.user_name
      else
        nil
      end
      
      if(github_compare and gitutils.repository_is_github?)
        message += " #{gitutils.github_compare_url(previous,latest)}"
      end
        
      self.speak(message)
      if(!settings.suppress_sounds and settings.post_deploy_success.play)
        self.play(settings.post_deploy_success.play)
      end
        
      if(!settings.suppress_deploy_log_paste)
        logger = Capistrano::CapatrossLogger
        log_output = File.open(logger.log_file_path).read
        self.paste(log_output)
      end
        
      @pre_announce_time = nil
    end
      
    def post_announce_failure(options = {})
      message = erberize(settings.post_deploy_failure.message,'post_deploy_failure message',options[:binding])        
      self.speak(message)
      if(!settings.suppress_sounds and settings.post_deploy_failure.play)
        self.play(settings.post_deploy_failure.play)
      end
        
      if(!settings.suppress_deploy_log_paste)
        logger = Capistrano::CapatrossLogger
        log_output = File.open(logger.log_file_path).read
        self.paste(log_output)
      end
      @pre_announce_time = nil
    end
      
  

            
    def will_do(options = {})
      puts "Before Deployment:"
      puts "Message: #{erberize(settings.pre_deploy.message,'pre_deploy message',options[:binding])}"
      if(!settings.suppress_sounds and settings.pre_deploy.play)
        puts "Will play sound: #{settings.pre_deploy.play}"
      else
        puts "Will not play sound"
      end
  
      puts "\n"
      puts "After Successful Deployment:"
      puts "Message: #{erberize(settings.post_deploy_success.message,'post_deploy_success message',options[:binding])}"
      if(!settings.suppress_sounds and settings.post_deploy_success.play)
        puts "Will play sound: #{settings.post_deploy_success.play}"
      else
        puts "Will not play sound"
      end
      if(!settings.suppress_deploy_log_paste)
        puts "Will paste deployment log"
      else
        puts "Will not paste deployment log"
      end
        
        
      puts "\n"
      puts "After Failed Deployment:"
      puts "Message: #{erberize(settings.post_deploy_failure.message,'post_deploy_failure message',options[:binding])}"
      if(!settings.suppress_sounds and settings.post_deploy_failure.play)
        puts "Will play sound: #{settings.post_deploy_failure.play}"
      else
        puts "Will not play sound"
      end
      if(!settings.suppress_deploy_log_paste)
        puts "Will paste deployment log"
      else
        puts "Will not paste deployment log"
      end
    end
      
    def whereto(capistrano_namespace)
      default_value =  ENV['SERVER'] || 'production'
      capistrano_namespace.fetch(:stage,default_value)
    end
      
    protected 
      
      
    def erberize(string,context,binding)
      begin
        ERB.new(string).result(binding)
      rescue NameError => error
        raise TemplateError, "Your #{context} message references an undefined value: #{error.name}. Set this in your capistrano deploy script"
      end
    end
        
      
    # Takes a period of time in seconds and returns it in human-readable form (down to minutes)
    # code from http://www.postal-code.com/binarycode/2007/04/04/english-friendly-timespan/
    def time_period_to_s(time_period,abbreviated=false,defaultstring='')
     out_str = ''
     interval_array = [ [:weeks, 604800], [:days, 86400], [:hours, 3600], [:minutes, 60], [:seconds, 1] ]
     interval_array.each do |sub|
      if time_period >= sub[1] then
        time_val, time_period = time_period.divmod( sub[1] )
        if(abbreviated)
          name = sub[0].to_s.first
          ( sub[0] != :seconds ? out_str += ", " : out_str += " " ) if out_str != ''
        else
          time_val == 1 ? name = sub[0].to_s.chop : name = sub[0].to_s
          ( sub[0] != :seconds ? out_str += ", " : out_str += " and " ) if out_str != ''
        end
        out_str += time_val.to_s + " #{name}"
      end
     end
     if(out_str.nil? or out_str.empty?)
       return defaultstring
     else
       return out_str
     end
    end
  end
end
