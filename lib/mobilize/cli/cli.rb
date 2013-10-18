# encoding: UTF-8
require 'optparse'
module Mobilize
  # holds all cli methods
  module Cli
    # decode base64 encoded strings that have been encrypted in travis
    def Cli.decode(args, options = {})
      @args, @options                 = args, options

      @opt_parser                     = OptionParser.new do |opts|
        @opts                         = opts
        @opts.banner                  = 'Usage: mob decode -p prefix -l length -f file'

        prefix_args                   = ['-p', '--prefix PREFIX', 'Prefix for environment variable to decode']
        @opts.on(*prefix_args)        { |prefix| @options[:prefix]    = prefix }

        length_args                   = ['-l', '--length L', 'Length of environment variable array to decode']
        @opts.on(*length_args)        { |length| @options[:length]    = length.to_i }

        file_args                     = ['-f', '--file F', 'File path to write decoded output to']
        @opts.on(*file_args)          { |file|   @options[:file_path] =  file }
      end
      @opt_parser.parse!                @args

      Mobilize::Travis.base64_decode    @options[:prefix],
                                        @options[:length],
                                        @options[:file_path]
    end
    # copy configuration to home folder if it's not already there
    def Cli.configure(args, options = {})
      @args, @options                 = args, options
      @opt_parser                     = OptionParser.new do |opts|
        @opts                         = opts
        @opts.banner                  = 'Usage: mob configure -n --name [-f --force] '

        force_args                    = ['-f', '--force', 'Force overwrite of existing .mob.yml']
        @opts.on(*force_args)         { |force| @options[:force] = true }

        name_args                     = ['-n', '--name [NAME]', 'File name from samples directory']
        @opts.on(*name_args)          { |name| @options[:name] = name }

      end
      @opt_parser.parse!                @args
      Mobilize::Config.write_sample     @options[:name],
                                        @options[:force]
    end
    # create log and pid folders, 
    # copy over configs
    # install and start god
    def Cli.resque(args, options = {})
      @args, @options                 = args, options
      @opt_parser                     = OptionParser.new do |opts|
        @opts                         = opts
        @opts.banner                  = 'Usage: mob resque <env> [-s --stop] '

        stop_args                     = ['-s', '--stop', 'stop god, stop resque-pool']
        @opts.on(*stop_args)          { |stop| @options[:stop] = true }
      end
      @opt_parser.parse!                @args

      Mobilize::Cli.god

      if                                @options[:stop]
        Mobilize::Logger.info           "god stop resque-pool-#{Mobilize.env}".popen4
        @pid_path                     = File.expand_path "#{Mobilize.home_dir}/pid/resque-pool-#{Mobilize.env}.pid"
        if File.exists?                 @pid_path
          Mobilize::Logger.info         "kill -2 #{File.read(@pid_path).strip}".popen4
          Mobilize::Logger.info         "Stopped resque workers on mobilize-#{Mobilize.env}"
        end
      else
        Mobilize::Logger.info           "god start resque-pool-#{Mobilize.env}".popen4
      end
    end

    def Cli.console(args)
      Mobilize.console
    end

    def Cli.god
      @god_file                       = "resque-pool-#{Mobilize.env}.rb"
      @pool_file                      = "resque-pool.yml"
      Mobilize::Config.write_sample     @god_file,  force:true
      Mobilize::Config.write_sample     @pool_file, force:true

      "gem install god".popen4       if "which god".popen4(false).empty?

      Mobilize::Logger.info             "god".popen4
      Mobilize::Logger.info             "god load #{Mobilize.root}/config/#{@god_file}".popen4
    end

    def Cli.box(args,options={})
      @args, @options                 = args, options
      @opt_parser                     = OptionParser.new do |opts|
        @opts                         = opts
        @opts.banner                  = "Usage: mob <env> box [-n --name NAME] [-a --action ACTION] [-p --purge] [-c --create]"

        name_args                     = ["-n", "--name NAME", "name of node"]
        @opts.on(*name_args)          { |name| @options[:name] = name }

        action_args                   = ["-a", "--action ACTION", "execute ACTION on given node"]
        @opts.on(*action_args)        { |action| @options[:action] = action }

        purge_args                    = ["-p", "--purge", "purge instance if existing"]
        @opts.on(*purge_args)         { |purge| @options[:purge] = true }

        create_args                   = ["-c", "--create", "create instance"]
        @opts.on(*create_args)        { |create| @options[:create] = true }

      end
      @opt_parser.parse!                @args

      [:purge, :create, :action].each { |cmd| Cli.send("box_#{cmd.to_s}", @options) if @options[cmd]}

    end

    def Cli.box_purge(options)
      @box                            = Mobilize::Box.find_or_create_by name: options[:name]
      @box.purge!                       Box.session
    end

    def Cli.box_create(options)
      @box                            = Mobilize::Box.find_or_create_by name: options[:name]
      @box.find_or_create_instance      Box.session
    end

    def Cli.box_action(options)
      @box                            = Mobilize::Box.find_or_create_by name: options[:name]
      @box.send options[:action]
    end
  end
end
