module Mobilize
  class Engine < Box
    def start
      _engine               = self
      _god_script_name      = "resque-pool-#{Mobilize.env}"
      _start_cmd            = "god && god load #{_engine.mobilize_config_dir}/#{_god_script_name}.rb && " +
                              "god start #{_god_script_name}"
      _engine.sh              _start_cmd
      Log.write               _start_cmd
      true
    end

    def stop
      _engine               = self
      _engine.sh              "god stop resque-pool-#{Mobilize.env}"
      _pid_path             = "#{_engine.mobilize_home_dir}/pid/resque-pool-#{Mobilize.env}.pid"
      _engine.sh              "kill -2 `cat #{_pid_path}`", false
    end

    def install
      _engine                  = self
      _engine.install_mobilize

      _engine.write_resque_pool_file
      _engine.write_god_file
      Log.write                "Mobilize engine installed on #{_engine.id}"
    end

    def write_resque_pool_file
      _engine               = self
      _resque_pool_path     = _engine.mobilize_config_dir + "/resque-pool.yml"
      _worker_count         = Mobilize.config.cluster.engines.workers.count
      _resque_pool_string   = {"test"=>{"mobilize-#{Mobilize.env}" => _worker_count}}.to_yaml
      _engine.write              _resque_pool_string, _resque_pool_path
      true
    end

    def write_god_file
      _engine               = self
      _god_file_name        = "resque-pool-#{Mobilize.env}.rb"

      _engine.cp              "#{Mobilize.config_dir}/#{_god_file_name}", "#{_engine.mobilize_config_dir}/#{_god_file_name}"
      true
    end
  end
end
