# encoding: UTF-8
require 'optparse'
require 'mobilize/extensions/string'
require 'pry'

module Mobilize
  # holds all cli methods
  module Cli
    autoload :Ci,        'mobilize/cli/ci'
    autoload :Box,       'mobilize/cli/box'
    autoload :Cluster,   'mobilize/cli/cluster'
    autoload :Log,       'mobilize/cli/log'
    autoload :Test,      'mobilize/cli/test'
    #adapted from travis CLI code: https://github.com/travis-ci/travis/blob/master/lib/travis/cli.rb
    def Cli.perform( _args )
      _name                    = _args[ 0 ]
      begin;                     return puts Mobilize.send _name;rescue;end
      _module                  = Cli.const_get _name.capitalize
      _module.perform            _args
    end
  end
end
