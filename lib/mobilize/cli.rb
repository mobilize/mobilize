# encoding: UTF-8
require 'optparse'
require 'mobilize/extensions/string'
require 'mobilize/logger'
require 'pry'

module Mobilize
  #Mobilize base methods
  def Mobilize.root
    File.expand_path "#{File.dirname(File.expand_path(__FILE__))}/../.."
  end
  def Mobilize.env
    ENV['MOBILIZE_ENV'] || "test"
  end
  def Mobilize.home_dir
    File.expand_path "~/.mobilize"
  end
  def Mobilize.log_dir
    "#{Mobilize.home_dir}/log"
  end
  def Mobilize.queue
    "mobilize-#{Mobilize.env}"
  end
  def Mobilize.console
    require 'mobilize'
    Mobilize.pry
  end

  # holds all cli methods
  module Cli
    autoload :Ci,        'mobilize/cli/ci'
    autoload :Box,       'mobilize/cli/box'

    # decode base64 encoded strings that have been encrypted in travis
    def Cli.configure(_args, _options = {})
      _opt_parser                     = OptionParser.new do |_opts|
        _opts.banner                  = 'Usage: mob configure NAME [-f --force]'

        force_args                    = ['-f', '--force', 'Force overwrite of existing .mob.yml']
        _opts.on(*force_args)         { |_force| _options[:force] = true }

      end
      _opt_parser.parse!                _args
      Mobilize::Config.write_sample     _options[:name], _options[:force]
    end

    def Cli.root
      puts Mobilize.root
    end

    def Cli.console
      Mobilize.console
    end

    #adapted from travis CLI code: https://github.com/travis-ci/travis/blob/master/lib/travis/cli.rb
    def Cli.perform(_args)
      _name                    = _args[0]
      begin;                     return Cli.send _name;rescue;end
      _module                  = Cli.const_get _name.capitalize
      _module.perform            _args
    end
  end
end
