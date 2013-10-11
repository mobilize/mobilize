require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname File.expand_path(__FILE__)
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
require "./test/fixtures/user"
require "./test/fixtures/job"
require "./test/fixtures/stage"
require "./test/fixtures/task"
require "./test/fixtures/trigger"

module Mobilize
  module Simulator
    def Simulator.resque
      #stop and restart resque workers
      @args                       = []
      Mobilize::Cli.resque          @args, stop: true
      Mobilize::Cli.resque          @args
      sleep 5
      @test_workers               = Resque.workers.select {|worker|
                                                            true if worker.queues.first == Mobilize.queue
                                                          }.compact

      @resque_pool_yml            = File.expand_path(Mobilize.home_dir) +
                                    "/resque-pool.yml"

      @resque_pool_config         = YAML.load_file @resque_pool_yml

      @num_workers                = @resque_pool_config[Mobilize.env][Mobilize.queue]

      Mobilize::Logger.error        "Could not start resque workers" unless @test_workers.length == @num_workers
    end
  end
end
