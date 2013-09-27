module Mobilize
  module Cli

    @@config = Mobilize.config

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
    #start up resque worker
    def Cli.resque
      worker = ::Resque::Worker.new(@@config.resque.queue)
      worker.term_child=1
      Logger.info("Started Resque worker")
      worker.work(5)
    end
    #copy configuration to home folder if it's not already there
    def Cli.configure(args)
      options={}
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
  end
end
