# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capatross/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jason Adam Young"]
  gem.email         = ["jayoung@extension.org"]
  gem.description = <<-EOF 
    Capatross is a gem extension to capistrano to post logs from a capistrano 
    deployment to an internal application for tracking deployments at eXtension. 
  EOF
  gem.summary       = %q{Post logs from a capistrano deploy to the deployment server, as well as a custom deploy-tracking application.}
  gem.homepage      = %q{https://github.com/extension/capatross}
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capatross"
  gem.require_paths = ["lib"]
  gem.version       = Capatross::VERSION
  gem.add_dependency('capistrano', '>= 2.11')
  gem.add_dependency('grit', '>= 2.4')
  gem.add_dependency('rest-client', '>= 1.6.7')
end
