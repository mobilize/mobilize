# encoding: UTF-8
require 'optparse'
module Mobilize
  # holds all cli methods
  module Cli
    # decode base64 encoded strings that have been encrypted in travis
    def Cli.decode(_args, _options = {})
      _opt_parser                     = OptionParser.new do |_opts|
        _opts.banner                  = 'Usage: mob decode prefix'
      end
      _opt_parser.parse!                _args

      Mobilize::Travis.base64_decode    _options[:prefix],
                                        _options[:length],
                                        _options[:file_path]
    end
    # copy configuration to home folder if it's not already there
    def Cli.configure(_args, _options = {})
      _opt_parser                     = OptionParser.new do |_opts|
        _opts.banner                  = 'Usage: mob configure NAME [-f --force]'

        force_args                    = ['-f', '--force', 'Force overwrite of existing .mob.yml']
        _opts.on(*force_args)         { |force| _options[:force] = true }

      end
      _opt_parser.parse!                _args
      Mobilize::Config.write_sample     _options[:name], _options[:force]
    end

    def Cli.root(_args)
      puts Mobilize.root
    end

    def Cli.console(_args)
      Mobilize.console
    end

    #adapted from travis CLI code: https://github.com/travis-ci/travis/blob/master/lib/travis/cli.rb
    def Cli.perform(_args)
      _args, _opts        = Cli.preparse(_args)
      _name               = _args.shift
      _command            = _args.shift
      _module             = "Mobilize::Cli::#{_name.capitalize}".constantize
      _module.send          _command, _opts
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
