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
  end
end
