require               'rubygems'
require               'bundler/setup'
require               'minitest/autorun'
ENV['MOBILIZE_ENV'] = 'test'
require               'mobilize'
#drop test database
Mongoid.purge!
#get fixtures
require               "./test/fixtures/github"
require               "./test/fixtures/user"
require               "./test/fixtures/job"
require               "./test/fixtures/stage"
require               "./test/fixtures/task"
require               "./test/fixtures/trigger"
