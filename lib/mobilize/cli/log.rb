require 'mobilize'
module Mobilize
  module Cli
    module Log
      def Log.perform(_args)
        _operator                 = _args[1]
        Mobilize::Log.send          _operator
      end
    end
  end
end
