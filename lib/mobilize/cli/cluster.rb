require 'mobilize'
module Mobilize
  module Cli
    module Cluster
      def Cluster.perform( _args )
        _operator                     = _args[ 1 ]
        if _operator == "test"
          Mobilize::Cluster.terminate
          Mobilize::Cluster.install
          Mobilize::Cluster.start
          #confirm all workers are present
          #tell master to put each test on Resque for processing
        else
          Mobilize::Cluster.perform       _operator
        end
      end
    end
  end
end
