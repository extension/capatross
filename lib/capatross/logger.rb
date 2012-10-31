#
# Original source from: https://github.com/engineyard/eycap/blob/master/lib/eycap/lib/ey_logger.rb
# Copyright (c) 2008-2011 Engine Yard, released under the MIT License
#
require 'tmpdir'
require 'fileutils'
module Capistrano
  class Logger

    def capatross_log(level, message, line_prefix = nil)
      CapatrossLogger.log(level, message, line_prefix) if CapatrossLogger.setup?
      log_without_capatross_logging(level, message, line_prefix)
    end

    unless method_defined?(:log_without_capatross_logging)
      alias_method :log_without_capatross_logging, :log
      alias_method :log, :capatross_log
    end

    def close
      device.close if @needs_close
      CapatrossLogger.close if CapatrossLogger.setup?
    end
  end

  class CapatrossLogger

    # Sets up the CapatrossLogger to begin capturing capistrano's logging.  You should pass the capistrano configuration
    def self.setup(configuration, options = {})
      @_configuration = configuration
      @_log_path = options[:deploy_log_path] || Dir.tmpdir
      @_log_path << "/" unless @_log_path =~ /\/$/
      FileUtils.mkdir_p(@_log_path)
      @_setup = true
      @_success = true
    end

    def self.log(level, message, line_prefix=nil)
      return nil unless setup?
      @release_name = @_configuration[:release_name] if @release_name.nil?
      @_log_file_path = @_log_path + @release_name + ".log" unless @_log_file_path
      @_deploy_log_file = File.open(@_log_file_path, "w") if @_deploy_log_file.nil?

      indent = "%*s" % [Logger::MAX_LEVEL, "*" * (Logger::MAX_LEVEL - level)]
      message.each_line do |line|
        if line_prefix
          @_deploy_log_file << "#{indent} [#{line_prefix}] #{line.strip}\n"
        else
          @_deploy_log_file << "#{indent} #{line.strip}\n"
        end
      end
    end

    def self.post_process
      unless ::Interrupt === $!
        puts "\n\nPlease wait while the log file is processed\n"
        # Should dump the stack trace of an exception if there is one
        error = $!
        unless error.nil?
          @_deploy_log_file << error.message << "\n"
          @_deploy_log_file << error.backtrace.join("\n")
          @_success = false
        end
        self.close

        hooks = [:any]
        hooks << (self.successful? ? :success : :failure)
        puts "Executing Post Processing Hooks"
        hooks.each do |h|
          @_post_process_hooks[h].each do |key|
            @_configuration.parent.find_and_execute_task(key)
          end
        end
        puts "Finished Post Processing Hooks"
      end
    end

    # Adds a post processing hook.
    #
    # Provide a task name to execute.  These tasks are executed after capistrano has actually run its course.
    #
    # Takes a key to control when the hook is executed.'
    # :any - always executed
    # :success - only execute on success
    # :failure - only execute on failure
    #
    # ==== Example
    #  Capistrano::CapatrossLogger.post_process_hook( "capatross:post_log", :any)
    #
    def self.post_process_hook(task, key = :any)
      @_post_process_hooks ||= Hash.new{|h,k| h[k] = []}
      @_post_process_hooks[key] << task
    end

    def self.setup?
      !!@_setup
    end

    def self.deploy_type
      @_deploy_type
    end

    def self.successful?
      !!@_success
    end

    def self.failure?
      !@_success
    end

    def self.log_file_path
      @_log_file_path
    end

    def self.close
      @_deploy_log_file.flush unless @_deploy_log_file.nil?
      @_deploy_log_file.close unless @_deploy_log_file.nil?
      @_setup = false
    end

  end
end
