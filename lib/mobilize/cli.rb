require 'travis/cli'
module Mobilize
  # holds all cli methods
  module Cli
    def Cli.root
      puts Mobilize.root
    end

    def Cli.console(args)
      Mobilize.console
    end

    def Cli.run(*args)
      _args, _opts                    = Cli.parse(args)
      _name                           = _args.shift unless _args.empty?
      _command                        = Cli.command(_name).new(_opts)
      _command.parse                    _args
      _command.execute
    end

    def Cli.command(name)
      _name                           = name
      _const_name                     = Cli.command_name _name
      _constant                       = Cli.const_get(const_name) if _const_name =~ /^[A-Z][a-z]+$/ and
                                                                     Cli.const_defined? _const_name
      if Cli.command? _constant
        _constant
      else
        $stderr.puts "unknown command #{_name}"
        exit 1
      end
    end

    def Cli.parse(unparsed, args = [], opts = {})
      _unparsed, _args, _opts = unparsed, args, opts

      case _unparsed
      when Hash  then _opts.merge! _unparsed
      when Array then _unparsed.each { |arg| Cli.parse(arg, _args, _opts) }
      else _args << _unparsed.to_s
      end

      [_args, _opts]
    end
  end
end
