require 'mobilize'
module Mobilize
  module Cli
    module Cron
      def Cron.operators
        { enqueue: "enqueue [operand] cron id into cluster" 
        }.with_indifferent_access
      end
      def Cron.perform
        _operator = ARGV.shift
        _operand  = ARGV.shift
        if _operator and 
          Cron.operators.keys.include? _operator
          return Mobilize::Cron.send          _operator, _operand
        end
        Cli.except Cron
      end
    end
  end
end
