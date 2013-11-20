require 'mobilize'
module Mobilize
  module Cli
    module Box
      def Box.operators
        { sh:    "execute operand on box",
          ssh:   "output shell command to create ssh connection"
        }.with_indifferent_access
      end
      
      def Box.perform
        _operator             = ARGV.shift

        if _operator
          if ARGV.length     == 1
             _box_name        = ARGV.shift
          else 
             _operand         = ARGV.shift
             _box_name        = ARGV.shift
          end
          _box                = Mobilize::Box.find_or_create_by_name _box_name.dup
          if _box.respond_to?   _operator
            _result           = _operand ? _box.send( _operator, _operand ) : _box.send( _operator )
            puts _result
            return true
          end
        end
        Cli.except Box
      end
    end
  end
end
