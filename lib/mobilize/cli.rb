require 'trollop'
module Mobilize
  module Cli
    def Cli.context_names

      _files = Dir.entries(    "#{ Mobilize.root }/lib/mobilize/cli/"
                          ).select{|_file| _file.ends_with? ".rb" }

      _files.map { |_file|     _file.basename.split( "." ).first }
    end

    Cli.context_names.each do |_context_name|
      autoload                 _context_name.capitalize.to_sym,
                               "mobilize/cli/#{ _context_name }"
    end

    def Cli.context( _name );  Cli.const_get _name.capitalize;  end

    def Cli.banner
      _context_rows          = Cli.context_names.map { |_context_name|
                               Cli.context( _context_name ).banner_row }

      _banner_rows           = [ Mobilize.gem_spec.description,
                                 "Usage: mob CONTEXT ...",
                                 "",
                                 "Available contexts:",
                                 "" ] +
                                 _context_rows +
                               [ "",
                                 "run `mob CONTEXT` for more info" ]

      Trollop::Parser.new do
        banner _banner_rows.join "\n"
      end
    end

    def Cli.perform
      _context_name        = ARGV.shift

      if _context_name and
        Mobilize.respond_to? _context_name
        Cli.route_command _context_name
      elsif Cli.context_names.include? _context_name
        Cli.context( _context_name ).perform ARGV
      else
        Trollop::with_standard_exception_handling Cli.banner do
          raise Trollop::HelpNeeded
        end
      end
    end

    def Cli.route_command( _name )
      _arity = Mobilize.method(_name ).arity.abs
      if _arity == 0
        puts Mobilize.send _name
      else
        puts Mobilize.send _name, ARGV
      end
    end
  end
end
