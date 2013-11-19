module Mobilize
  class Engine < Mobilize::Box
    after_initialize :set_self
    def set_self;    @box, @engine = self, self;end

    def queue
      @engine.id
    end

    def start
      _god_script_name      = "resque-pool-#{ Mobilize.env }"
      _start_cmd            = "god && god load #{ @engine.mobilize_config_dir }/#{ _god_script_name }.rb && " +
                              "god start #{ _god_script_name }"
      @engine.sh              _start_cmd
      Log.write               _start_cmd, "INFO", @engine
      true
    end

    def stop
      @engine.sh              "god stop resque-pool-#{ Mobilize.env }"
      _pid_path             = "#{ @engine.mobilize_home_dir }/pid/resque-pool-#{ Mobilize.env }.pid"
      @engine.sh              "kill -2 `cat #{ _pid_path }`", false
    end

    def install
      @engine.install_mobilize
      @engine.write_resque_pool_file
      @engine.create_log_dir
      @engine.write_god_file
    end

    def upgrade
      @engine.install_gem_local
    end

    def create_log_dir
      @engine.sh              "mkdir -p #{ @engine.mobilize_home_dir }/log"
    end

    def write_resque_pool_file
      _resque_pool_path     = @engine.mobilize_config_dir + "/resque-pool.yml"
      _worker_count         = Mobilize.config.cluster.engines.workers.count
      _resque_pool_string   = { Mobilize.env =>
                                { "#{ Mobilize.queue },#{ @engine.queue }" =>
                                  _worker_count } }.to_yaml
      @engine.write              _resque_pool_string, _resque_pool_path
      true
    end

    def write_god_file
      @engine               = self
      _god_file_name        = "resque-pool-#{ Mobilize.env }.rb"
      @engine.cp              "#{ Mobilize.config_dir }/#{ _god_file_name }",
                              "#{ @engine.mobilize_config_dir }/#{ _god_file_name }"
      true
    end
  end
end
