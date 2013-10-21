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
  end
end
