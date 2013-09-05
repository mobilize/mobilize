# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mobilize/version'

Gem::Specification.new do |spec|
  spec.name          = "mobilize"
  spec.version       = Mobilize::VERSION
  spec.authors       = ["Cassio Paes-Leme"]
  spec.email         = ["cassio.paesleme@gmail.com"]
  spec.description   = %q{Google Drive UI, Resque multithreading, SSH processing, Mongo Backend for scheduled jobs}
  spec.summary       = %q{Google Drive UI, Resque multithreading, SSH processing, Mongo Backend for scheduled jobs}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bundler","1.3.5"
  spec.add_runtime_dependency "rake","10.1.0"
  spec.add_runtime_dependency "aws","2.4.5"
  spec.add_runtime_dependency "gmail","0.4.0"
  spec.add_runtime_dependency "google_drive","0.3.6"
  spec.add_runtime_dependency "resque","1.24.1"
  spec.add_runtime_dependency "redis-objects"
  spec.add_runtime_dependency "mongoid", "3.1.4"
  spec.add_runtime_dependency "popen4","0.1.2"
  spec.add_runtime_dependency "pry","0.9.12.2"
  spec.add_runtime_dependency "pry-doc","0.4.6"
end
