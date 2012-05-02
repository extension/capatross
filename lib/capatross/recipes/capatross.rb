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
      
    ## no descriptions for the following task - meant to be hooked by capistrano
    task :start do
      set(:whereto,capatross_core.whereto(self))
      capatross_core.merge_deploydata(capatross_id: capatross_core.capatross_id,
                                      deployer_email: capatross_core.gitutils.user_email,
                                      deployer_name:  capatross_deployer,
                                      previous_revision: current_revision,
                                      start: Time.now.utc,
                                      location: whereto)
      start_posted = capatross_core.post_deploydata
      capatross_core.merge_deploydata(start_posted: start_posted)
    end
    
    ## no descriptions for the following task - meant to be hooked by capistrano
    task :finish do
      set(:whereto,capatross_core.whereto(self))
      logger = Capistrano::CapatrossLogger
      if(logger.successful?)
        capatross_core.merge_deploydata(deployed_revision: current_revision, success: true, finish: Time.now.utc)
      else
        capatross_core.merge_deploydata(success: false, finish: Time.now.utc)
      end
      
      capatross_core.merge_deploydata(deploy_log: File.open(logger.log_file_path).read)
      finish_posted = capatross_core.post_deploydata
      capatross_core.merge_deploydata(finish_posted: finish_posted)
      outputfile = capatross_core.write_deploydata
      if(capatross_core.settings.copy_log_to_server)
        run "mkdir -p #{shared_path}/capatross_logs"
        put File.open(outputfile).read, "#{shared_path}/capatross_logs/#{File.basename(outputfile)}"
      end      
    end  
              
  end
end

Capistrano::CapatrossLogger.post_process_hook("capatross:finish",:any)
