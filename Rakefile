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
end
task :default => :test

#resque
require 'mobilize'
require 'resque/tasks'
require 'resque/pool/tasks'

task "resque:setup" do
  puts "Starting Resque..."
  puts ENV
  Redis.connect url: ENV['REDIS_URL'], port: ENV['REDIS_PORT']
end
