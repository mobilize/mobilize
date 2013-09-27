require 'optparse'
module Mobilize
  module Cli
    #decode base64 encoded strings that have been encrypted in travis
    def Cli.decode(args,options={})
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: mob decode -p prefix -l length -f file"

        opts.on("-p", "--prefix PREFIX", "Prefix for environment variable to decode") do |p|
          options[:prefix] = p
        end

        opts.on("-l", "--length L", "Length of environment variable array to decode") do |l|
          options[:length] = l.to_i
        end

        opts.on("-f", "--file F", "File path to write decoded output to") do |f|
          options[:file_path] = f
        end
      end
      opt_parser.parse!(args)
      Mobilize::Travis.base64_decode(options[:prefix],options[:length],options[:file_path])
    end
    #copy configuration to home folder if it's not already there
    def Cli.configure(args,options={})
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: mob configure -n --name [-f --force] "

        opts.on("-f", "--force", "Force overwrite of existing .mob.yml") do |f|
          options[:force] = true
        end

        opts.on("-n", "--name [NAME]", "File name; can be mob.yml, mongoid.yml, or resque-pool.yml") do |n|
          options[:name] = n
        end

      end
      opt_parser.parse!(args)
      Mobilize::Config.write_sample(options[:name],options[:force])
    end
    #create log and pid folders, 
    #copy over configs
    #install and start god
    def Cli.resque(args,options={})
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: mob resque <env> [-s --stop] "

        opts.on("-s", "--stop", "stop god, stop resque-pool") do |s|
          options[:stop] = true
        end
      end
      opt_parser.parse!(args)
 
      god_file = "resque-pool-#{Mobilize.env}.rb"
      pool_file = "resque-pool.yml"
      [god_file,pool_file].each do |file_name|
        Mobilize::Config.write_sample(file_name,force:true)
      end
      if "which god".popen4(false).empty?
        "gem install god".popen4
      end
      ["god",
      "god load #{Mobilize.root}/config/#{god_file}"
      ].each do |cmd|
        Logger.info(cmd.popen4)
      end
      if options[:stop]
        ["god stop resque-pool-#{Mobilize.env}",
         "kill -2 `cat #{Mobilize.config.resque.pid_dir}/resque-pool-#{Mobilize.env}.pid`"
        ].each do |cmd|
          Logger.info(cmd.popen4)
        end
      else
        Logger.info("god start resque-pool".popen4)
      end
    end
  end
end
