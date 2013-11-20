require 'mobilize'
module Mobilize
  module Cli
    module Cluster
      def Cluster.operators
        { install:   "install all binaries/gems and write all configs into engines and master",
          upgrade:   "install version of Mobilize from run directory into engines and master, then restart",
          stop:      "stop all engines and master",
          start:     "start all engines and master",
          restart:   "stop then start all engines and master",
          terminate: "terminate all boxes in cluster",
        }.with_indifferent_access
      end
      def Cluster.perform
        _operator                       = ARGV.shift
        if _operator and
          Cluster.operators.keys.include? _operator
          Mobilize::Cluster.send          _operator
        end
        Cli.except Cluster
      end
    end
  end
end
