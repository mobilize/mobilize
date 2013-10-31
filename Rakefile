require "bundler/gem_tasks"

#
# Tests
#
require 'rake/testtask'
Rake::TestTask.new do |test|
  test.verbose = true
  test.libs << "test"
  test.libs << "lib"
  test.test_files = FileList['test/**/*_test.rb']
  ENV['MOBILIZE_ENV'] = 'test'
end
task :default => :test

#resque
require 'mobilize'
require 'resque/tasks'
require 'resque/pool/tasks'
require 'pp'
task "resque:setup" do
  puts "Starting Resque..."
  Resque.redis = Redis.new host:     Mobilize.config.redis.host,
                           port:     Mobilize.config.redis.port,
                           password: Mobilize.config.redis.password
end

require 'rake/hooks'
after :install do
#copy sha1 revision into gem directory
  _revision              = "git log -1 --pretty=format:%H".popen4
  _root_dir              = "which mob".popen4.dirname.dirname
  _revision_path         = "#{_root_dir}/gems/mobilize-#{Mobilize::VERSION}/REVISION"
  File.write               _revision_path, _revision
end
