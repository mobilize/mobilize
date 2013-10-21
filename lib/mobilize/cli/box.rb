module Mobilize
  # holds all cli methods
  module Cli
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
