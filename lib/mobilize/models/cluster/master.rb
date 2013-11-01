module Mobilize
  class Master < Mobilize::Box
    def Master.config;        Mobilize.config.cluster.master;end

    def start
      _master               = self
      _master.start_resque_web
    end

    def stop
      _master               = self
      _master.stop_resque_web
    end

    def start_resque_web
      _master               = self
      _redis                = Mobilize.config.redis
      _resque_auth_path     = "#{_master.mobilize_config_dir}/resque-web-auth.rb"
      _master.sh              "resque-web #{_resque_auth_path} -r #{_redis.host}:#{_redis.port}:0"
    end

    def stop_resque_web
      _master               = self
      _master.sh              "ps aux | grep resque-web " +
                              "| awk '{print $2}' | xargs kill", false
    end

    def install
      _master                        = self
      _master.install_mobilize
      _master.install_resque_web_routing
      _master.write_resque_web_auth
    end

    def install_resque_web_routing
      _master         = self
      #add iptables reroute for port 80, set iptables persistent
      _master.sh        "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 5678"
    end

    def write_resque_web_auth
      _master                    = self
      _config                    = Mobilize.config.cluster.master.resque_web

      _resque_web_auth_script    = "Resque::Server.use(Rack::Auth::Basic) do |_user, _password|\n" +
                                   "[_user, _password] == ['#{_config.username}', '#{_config.password}']\n" +
                                   "end"

      _master.write                _resque_web_auth_script, "#{_master.mobilize_config_dir}/resque-web-auth.rb"
      true
    end
  end
end
