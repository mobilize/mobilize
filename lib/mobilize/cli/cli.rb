module Mobilize
  module Cli
    #decode base64 encoded strings that have been encrypted in travis
    def Cli.decode(args)
      options={}
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
    def Cli.configure(args)
      options={}
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: mob configure [-f --force]"

        opts.on("-f", "--force", "Force overwrite of existing .mob.yml") do |f|
          options[:force] = true
        end
      end
      opt_parser.parse!(args)
      mob_yml_path = File.expand_path("~/.mob.yml")
      if File.exists?(mob_yml_path) and options[:force] != true
        Mobilize:: Logger.error("~/.mob.yml found; please run with -f  option to overwrite with default")
      else
        if File.exists?(mob_yml_path)
          Mobilize:: Logger.info("Forcing overwrite of existing ~/.mob.yml")
        end
        FileUtils.cp("#{Mobilize.root}/samples/mob.yml",mob_yml_path)
        Mobilize:: Logger.info("Wrote default configs to ~/.mob.yml")
      end
    end
  end
end
