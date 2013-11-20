require 'mobilize'
module Mobilize
  module Cli
    module Log
      def Log.operators
        { tail:   "tail [condition] - tail logs with optional where clause operand in activemodel syntax",
        }.with_indifferent_access
      end
      def Log.perform
        _operator            = ARGV.shift
        if   _operator           == 'tail'

             _condition           = ARGV.shift

             _condition           = YAML.easy_hash_load( _condition ) if _condition

             Mobilize::Log.send     'tail', *[ _condition ]
        end
        Cli.except Log
      end
    end
  end
end
