# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'capistrano'
require 'grit'

require 'capatross/logger'
require 'capatross/version'
require 'capatross/deep_merge' unless defined?(DeepMerge)
require 'capatross/options'
require 'capatross/git_utils'
require 'capatross/core'

module Capatross
  def self.extended(configuration)
    configuration.load do    
      set :capatross_core, Capatross::Core.new
      set :capatross_deployer, capatross_core.deployer    
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capatross)

  Capistrano::Configuration.instance(:must_exist).load do
    # load the recipes
    Dir.glob(File.join(File.dirname(__FILE__), '/capatross/recipes/*.rb')).sort.each { |f| load f }
    before "deploy", "capatross:pre_announce"
  end
end
