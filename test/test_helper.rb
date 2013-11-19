require               'rubygems'
require               'bundler/setup'
require               'minitest/autorun'
ENV['MOBILIZE_ENV'] = 'test'
require               'mobilize'
#get fixtures
require               "./test/fixtures/github"
require               "./test/fixtures/user"
require               "./test/fixtures/cron"
require               "./test/fixtures/crontab"
require               "./test/fixtures/stage"
require               "./test/fixtures/task"
