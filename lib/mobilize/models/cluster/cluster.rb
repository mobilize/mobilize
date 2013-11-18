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

    def Cluster.thread( _call )
      Log.write          "Calling #{ _call } on master and engines"
      _names           = Cluster.engine_names + Cluster.master_name.to_a
      _procs           = []

      _names.each { |_name|
        _Model         = _name == _names.last ? Master : Engine
        _proc          = Proc.new {
          _box         = _Model.find_or_create_by_name _name
          begin;         _box.send _call;
            Log.write    "#{ _box.name } #{ _call } complete";
          rescue      => _exc;
            Log.write    "#{ _box.name } #{ _call } failed with #{ _exc.to_s }", "FATAL"
          end
        }
        _procs        << _proc}
      _result          = _procs.thread
      _result
    end

    def Cluster.resque_web_url
      _username                  = Mobilize.config.cluster.master.resque_web.username
      _password                  = Mobilize.config.cluster.master.resque_web.password
      "http://#{ _username }:#{ _password }@#{ Cluster.master.dns }"
    end

    def Cluster.view
      "open #{ Cluster.resque_web_url }/overview".popen4
    end

    def Cluster.resque_web_workers
      _master                    = Master.first
      _worker_string             = _master.sh "mob script 'Resque.workers'"
      _worker_array              = _worker_string.split("\n" ).map {|_worker_row| _worker_row.split( "," ).last }
      _worker_array.group_count
    end

    def Cluster.engine_names
      _engine_count              = Mobilize.config.cluster.engines.count
      _engine_count.times.map { |_box_i|
                                 _padded_i        = (_box_i + 1).to_s.rjust(2,'0')
                                 _engine_name     = "mobilize-engine-#{ Mobilize.env }-#{ _padded_i }"
                                 _engine_name
                              }
    end

    def Cluster.wait_for_engines
      _engines                         = Mobilize::Cluster.engines
      _workers_per_engine              = Mobilize.config.cluster.engines.workers.count
      _resque_web_workers              = Mobilize::Cluster.resque_web_workers
      #wait for workers to start
      _attempts                        = 0
      while _resque_web_workers.length       < _engines.length and
            _resque_web_workers.values.uniq != [ _workers_per_engine ] and
            _attempts <= 10
        Log.write                        "waiting for workers on all engines, attempt #{ ( _attempts + 1 ).to_s }"
        _resque_web_workers            = Mobilize::Cluster.resque_web_workers
        sleep 5
        _attempts                     += 1
      end
      Log.write( "Worker engine start failed", "FATAL" ) if _resque_web_workers.length       <   _engines.length or
                                                            _resque_web_workers.values.uniq != [ _workers_per_engine ]
      true
    end
  end
end
