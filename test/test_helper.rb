require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname(File.expand_path(__FILE__))
#set test environment
ENV['MOBILIZE_ENV'] = 'test'
require 'mobilize'
#drop test database
Mongoid.purge!
#get fixtures
require "./test/fixtures/ec2"
require "./test/fixtures/github"
require "./test/fixtures/gfile"
require "./test/fixtures/ssh"
require "./test/fixtures/job"
require "./test/fixtures/user"
require "./test/fixtures/task"
require "./test/fixtures/trigger"

module Mobilize
  module Simulator
    def Simulator.resque
      #stop and restart resque workers
      Mobilize::Cli.resque([],stop: true)
      Mobilize::Cli.resque([])
      sleep 5
      test_workers = Resque.workers.map do |w|
        w if w.queues.first=="mobilize-test"
      end.compact
      Mobilize::Logger.error("Could not start resque workers") unless test_workers.length==5
    end
  end
end
