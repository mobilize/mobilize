require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname File.expand_path(__FILE__)
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
