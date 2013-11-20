require 'trollop'
module Mobilize
  module Cli
    def Cli.operators
      { box:     "run commands and install packages on cluster boxes",
        ci:      "use to encrypt and decrypt ssh keys for ci",
        cluster: "prepare and monitor cluster boxes",
        cron:    "enqueue crons on cluster",
        log:     "tail and query logs",
        test:    "execute tests in parallel on cluster",
        root:    "display gem root directory",
        console: "bring up pry console in Mobilize context",
        script:  "execute [operand] in Mobilize context"
      }.with_indifferent_access
    end

    Cli.operators.keys.each do |_name|
      _file_path = "#{ Mobilize.root }/lib/mobilize/cli/#{ _name.to_s }.rb"
      if File.exists? _file_path
        autoload      _name.capitalize, _file_path
      end
    end

    def Cli.operator_rows ( _Cli = Cli )
      "Available operators:\n" +
      "\n" +
      _Cli.operators.map { |_name, _description| [ _name, _description ].join " - " }.join( "\n" )
    end

    def Cli.banner( _Cli = Cli)
      _subcommand = _Cli == Cli ? "" : " #{ _Cli.to_s.split( "::" ).last.downcase }"
      _banner_rows = Mobilize.gem_spec.description +
                    "Usage: mob#{_subcommand} <operator> [operand] \n" +
                    "\n" +
                     Cli.operator_rows( _Cli ) +
                     "\n" +
                     "\n" +
                     "run `mob#{ _subcommand } <operator>` for more info"
      Trollop::Parser.new do
        banner _banner_rows
      end
    end

    def Cli.perform
      _operator        = ARGV.shift

      if         Cli.operators.keys.include?     _operator
        if       Cli.respond_to?            _operator
          return Cli.send _operator
        else
          return Cli.const_get(             _operator.capitalize ).perform
        end
      end
      Cli.except
    end

    def Cli.except( _Cli = Cli )
      Trollop::with_standard_exception_handling Cli.banner( _Cli ) do
        raise Trollop::HelpNeeded
      end
    end

    def Cli.root;    puts Mobilize.root; end
    def Cli.console; Mobilize.console; end
    def Cli.script;  puts Mobilize.script; end
  end
end
