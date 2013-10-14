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
  Resque.redis = Redis.new host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT']
end
