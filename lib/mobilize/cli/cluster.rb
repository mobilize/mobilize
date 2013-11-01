require 'mobilize'
module Mobilize
  module Cli
    module Cluster
      def Cluster.perform(_args)
        _operator                     = _args[1]
        Mobilize::Cluster.perform       _operator
      end
    end
  end
end
