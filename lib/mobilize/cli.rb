# encoding: UTF-8
module Mobilize
  # holds all cli methods
  module Cli
    autoload :Ci,              'mobilize/cli/ci'
    autoload :Box,             'mobilize/cli/box'
    autoload :Cluster,         'mobilize/cli/cluster'
    autoload :Cron,            'mobilize/cli/cron'
    autoload :Log,             'mobilize/cli/log'
    autoload :Test,            'mobilize/cli/test'

    def Cli.perform( _args )
      _name                    = _args[ 0 ]
      begin;                     return puts Mobilize.send _name;rescue;end
      _module                  = Cli.const_get _name.capitalize
      _module.perform            _args
    end
  end
end
