require 'mobilize'
module Mobilize
  module Cli
    module Cluster
      def Cluster.perform( _args )
        _operator                     = _args[ 1 ]
        if _operator == "test"
          [ "terminate", "install", "start" ].each do |_action|
            Mobilize::Cluster.perform _action
          end
          _username                          = Mobilize.config.cluster.master.resque_web.username
          _password                          = Mobilize.config.cluster.master.resque_web.password
          _html_string                       = "curl http://#{ _username }:#{ _password }@#{ Cluster.master.dns }".popen4
          _html_doc                          = Nokogiri::HTML _html_string
          _text_rows                         = _html_doc.css( 'table.queues' ).css( 'tr' )
          _value_array_array                 = _text_rows.map { |_node| _node.text.strip.split_strip( "\n" ) }
          _value_hash                        = _value_array_array.tuples_to_hash
          _workers_per_engine                = Mobilize.config.cluster.engines.workers.count
          _engines                           = Mobilize::Cluster.engines
          _engines.each do |_engine|
            _value_hash[ _engine.hostname ] == _workers_per_engine.to_s
          end
          _total_workers                     = _workers_per_engine * _engines
          _value_hash[ "all workers" ]      == _total_workers.to_s
          #tell master to put each test on Resque for processing
        else
          Mobilize::Cluster.perform            _operator
        end
      end
    end
  end
end
