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
        _opts.on(*force_args)         { |force| _options[:force] = true }

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
      _args, _opts        = Cli.preparse(_args)
      _name               = _args.shift
      return Cli.send _name if defined?(Cli.send _name)
      _command            = _args.shift
      _target             = _args.shift
      _module             = Cli.const_get _name.capitalize
      _module.send          _command, _target, _opts
    end

    def Cli.preparse(_unparsed, _args = [], _opts = {})
      case   _unparsed
        when Hash  then  _opts.merge!      _unparsed
        when Array then  _unparsed.each { |_expression| Cli.preparse(_expression, _args, _opts) }
        else _args    << _unparsed.to_s
      end
      [_args, _opts]
    end
  end
end
