# Capatross

Capatross is a gem extension to capistrano to post logs from a capistrano 
deployment to an internal application for tracking deployments at eXtension. 
Settings are configurable in a "config/capatross.yml" and/or 
"config/capatross.local.yml" file.

Captross borrows code concepts from [capistrano-campout](https://github.com/jasonadamyoung/capistrano-campout) – which
in turn, borrows from other projects. See the capistrano-campout Readme for more details 

## Installation

Add this line to your application's Gemfile:

    gem 'capatross'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capatross

Note: capatross is not published to rubygems.org - it's available only on eXtension's internal gem server.

## Setup

You can generate a configuration by running

    capatross generate_config

This will prompt you for your campfire configuration settings and create config/capatross.yml and config/capatross.local.yml files for you, adding config/capatross.local.yml to your .gitignore file (if present) and adding a require 'capatross' to your config/deploy.rb file.

## Manual Setup

Alternatively add a:

	require "capatross"  

to your capistrano deploy.rb and create a config/capatross.yml and/or a config/capatross.local.yml with your capatross settings (required)

[Settings TBD]

"config/capatross.yml" is meant to be a pre-project file and can contain global settings for everyone. 

"config/capatross.local.yml" is meant as a local/private configuration file - I'd recommend adding the file to the .gitignore

## Settings

Run the 'capatross generate_config' command - and the config/capatross.yml file will have a list of all the known settings.

## Contributing

capatross is an internal eXtension project. We keep it open so that folks can keep track of our efforts and process

## Sources

Capatross includes code and ideas from the following projects:

* [rails_config](https://github.com/railsjedi/rails_config) Copyright © 2010 Jacques Crocker
* [deep_merge](https://github.com/danielsdeleo/deep_merge) Copyright © 2008 Steve Midgley, now mainted by Daniel DeLeo
* [eycap](https://github.com/engineyard/eycap) Copyright © 2008-2011 Engine Yard
* [capistrano-campout](https://github.com/jasonadamyoung/capistrano-campout) Copyright © 2012 Jason Adam Young


