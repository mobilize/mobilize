module Mobilize
  # holds all cli methods
  module Cli
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
  end
end
