require 'mobilize'
module Mobilize
  module Cli
    module Cron
      def Cron.banner_row
        "cron"
      end
      def Cron.perform( _args )
         _operator, _operand   = _args[ 1 ], _args[ 2 ]

         Mobilize::Cron.send     _operator, _operand
      end
    end
  end
end
