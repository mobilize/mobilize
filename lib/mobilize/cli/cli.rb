# encoding: UTF-8
require 'optparse'
module Mobilize
  # holds all cli methods
  module Cli
    # decode base64 encoded strings that have been encrypted in travis
    def Cli.decode(args, options = {})
      _args, _options                 = args, options

      _opt_parser                     = OptionParser.new do |opts|
        _opts                         = opts
        _opts.banner                  = 'Usage: mob decode -p prefix -l length -f file'

        prefix_args                   = ['-p', '--prefix PREFIX', 'Prefix for environment variable to decode']
        _opts.on(*prefix_args)        { |prefix| _options[:prefix]    = prefix }

        length_args                   = ['-l', '--length L', 'Length of environment variable array to decode']
        _opts.on(*length_args)        { |length| _options[:length]    = length.to_i }

        file_args                     = ['-f', '--file F', 'File path to write decoded output to']
        _opts.on(*file_args)          { |file|   _options[:file_path] =  file }
      end
      _opt_parser.parse!                _args

      Mobilize::Travis.base64_decode    _options[:prefix],
                                        _options[:length],
                                        _options[:file_path]
    end
    # copy configuration to home folder if it's not already there
    def Cli.configure(args, options = {})
      _args, _options                 = args, options
      _opt_parser                     = OptionParser.new do |opts|
        _opts                         = opts
        _opts.banner                  = 'Usage: mob configure -n --name [-f --force] '

        force_args                    = ['-f', '--force', 'Force overwrite of existing .mob.yml']
        _opts.on(*force_args)         { |force| _options[:force] = true }

        name_args                     = ['-n', '--name [NAME]', 'File name from samples directory']
        _opts.on(*name_args)          { |name| _options[:name] = name }

      end
      _opt_parser.parse!                _args
      Mobilize::Config.write_sample     _options[:name],
                                        _options[:force]
    end
    # create log and pid folders, 
    # copy over configs
    # install and start god
    def Cli.resque(args, options = {})
      _args, _options                 = args, options
      _opt_parser                     = OptionParser.new do |opts|
        _opts                         = opts
        _opts.banner                  = 'Usage: mob resque <env> [-s --stop] '

        stop_args                     = ['-s', '--stop', 'stop god, stop resque-pool']
        _opts.on(*stop_args)          { |stop| _options[:stop] = true }
      end
      _opt_parser.parse!                _args

      Mobilize::Cli.god

      if                                _options[:stop]
        Mobilize::Logger.write          "god stop resque-pool-#{Mobilize.env}".popen4
        _pid_path                     = File.expand_path "#{Mobilize.home_dir}/pid/resque-pool-#{Mobilize.env}.pid"
        if File.exists?                 _pid_path
          Mobilize::Logger.write        "kill -2 #{File.read(_pid_path).strip}".popen4
          Mobilize::Logger.write        "Stopped resque workers on mobilize-#{Mobilize.env}"
        end
      else
        Mobilize::Logger.write          "god start resque-pool-#{Mobilize.env}".popen4
      end
    end

    def Cli.root(args, options = {})
      puts Mobilize.root
    end

    def Cli.console(args)
      Mobilize.console
    end

    def Cli.god
      _god_file                       = "resque-pool-#{Mobilize.env}.rb"
      _pool_file                      = "resque-pool.yml"
      Mobilize::Config.write_sample     _god_file,  force:true
      Mobilize::Config.write_sample     _pool_file, force:true

      "gem install god".popen4       if "which god".popen4(false).empty?

      Mobilize::Logger.write            "god".popen4
      Mobilize::Logger.write            "god load #{Mobilize.root}/config/#{_god_file}".popen4
    end

    def Cli.box(args,options={})
      _args, _options                 = args, options
      _opt_parser                     = OptionParser.new do |opts|
        _opts                         = opts
        _opts.banner                  = "Usage: mob <env> box [-n --name NAME] [-a --action ACTION] [-p --purge] [-c --create]"

        name_args                     = ["-n", "--name NAME", "name of node"]
        _opts.on(*name_args)          { |name| _options[:name] = name }

        action_args                   = ["-a", "--action ACTION", "execute ACTION on given node"]
        _opts.on(*action_args)        { |action| _options[:action] = action }

      end
      _opt_parser.parse!                _args

      _box                            = Mobilize::Box.find_or_create_by_name _options[:name]
      _box.send options[:action]

    end
  end
end
