require 'mobilize'
module Mobilize
  module Cli
    module Test
      def Test.perform(_args)
        _operator                     = _args[1]
        Mobilize::Test.perform       _operator
      end
    end
  end
end
