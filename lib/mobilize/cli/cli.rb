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

    #execute command on given ec2 node
    #with user defined by ENV['MOB_EC2_USER']
    def Cli.ec2(args)
      options={}
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: mob ec2 -n node -c command"

        opts.on("-n", "--node NODE", "name of ec2 node on which to execute command") do |n|
          options[:node_name] = n
        end

        opts.on("-c", "--command C", "Command to execute on the node") do |c|
          options[:command] = c
        end
      end
      opt_parser.parse!(args)
      #by default, execute on master node
      options[:node_name] ||= ENV['MOB_EC2_MASTER_NAME']
      Mobilize::Ec2.find_by(options[:node_name]).execute(options[:command])
    end
  end
end
