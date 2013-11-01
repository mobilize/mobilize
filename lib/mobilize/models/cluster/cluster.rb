module Mobilize
  # There is one Cluster per environment;
  # it has one Master and many Engines
  module Cluster
    def Cluster.master_name
      "mobilize-master-#{Mobilize.env}-01"
    end
    def Cluster.master
      Master.find_or_create_by_name Cluster.master_name
    end
    def Cluster.engines
      Cluster.engine_names.map { |_engine_name|
        Engine.find_or_create_by_name _engine_name
      }
    end
    def Cluster.perform( _action )

      begin;return Cluster.send   _action;rescue;end

      _result    = Cluster.thread _action
      _result
    end

    #get procs for engine and master and call them in threads
    def Cluster.thread( _call )
      _names           = Cluster.engine_names + Cluster.master_name.to_a
      _procs           = []

      _names.each_with_index { |_name, _name_i|
        _Model         = _name == _names[-1] ? Master : Engine
        _proc          = Proc.new {
          _box         = _Model.find_or_create_by_name _name
          _box.send       _call}
        _procs        << _proc}
      _result          = _procs.thread
      _result
    end

    def Cluster.view
      "open http://#{Cluster.master.dns}".popen4
    end

    def Cluster.engine_names
      _engine_count     = Mobilize.config.cluster.engines.count
      _engine_count.times.map { |_box_i|
                                 _padded_i        = (_box_i + 1).to_s.rjust(2,'0')
                                 _engine_name     = "mobilize-engine-#{ Mobilize.env }-#{ _padded_i }"
                                 _engine_name
                              }
    end
  end
end
