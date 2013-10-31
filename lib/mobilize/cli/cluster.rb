require 'mobilize'
module Mobilize
  module Cli
    module Cluster
      def Cluster.perform(_args)
        _operator                     = _args[1]
        Mobilize::Box.send [ _operator, "cluster" ].join "_"
      end
    end
  end
end
