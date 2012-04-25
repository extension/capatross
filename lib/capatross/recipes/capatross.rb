# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

#
# Post process hooks inspired by: https://github.com/engineyard/eycap/blob/master/lib/eycap/lib/ey_logger_hooks.rb
# Copyright (c) 2008-2011 Engine Yard, released under the MIT License
#

Capistrano::Configuration.instance(:must_exist).load do
  namespace :capatross do
    
    ## no descriptions for the following tasks - meant to be hooked by capistrano
    task :pre_announce do
      set(:whereto,capatross_core.whereto(self))
      logger.info "#{capatross_deployer} is starting to deploy #{application} to #{whereto}"
    end
    
    task :post_announce_success do
      set(:whereto,capatross_core.whereto(self))
      logger.info "#{capatross_deployer} successfully deployed #{application} to #{whereto}"
    end
    
    task :post_announce_failure do
      set(:whereto,capatross_core.whereto(self))
      logger.error "#{capatross_deployer} successfully deployed #{application} to #{whereto}"
    end
    
    task :copy_log, :except => { :no_release => true} do
      if(capatross_core.settings.copy_log_to_server)
        logger = Capistrano::CapatrossLogger
        run "mkdir -p #{shared_path}/deploy_logs"
        put File.open(logger.log_file_path).read, "#{shared_path}/deploy_logs/#{logger.remote_log_file_name}"
      end
    end
  end
end

Capistrano::CapatrossLogger.post_process_hook("capatross:post_announce_success",:success)
Capistrano::CapatrossLogger.post_process_hook("capatross:post_announce_failure",:failure)
Capistrano::CapatrossLogger.post_process_hook("capatross:copy_log",:any)
