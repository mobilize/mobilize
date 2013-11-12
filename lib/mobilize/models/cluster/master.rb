module Mobilize
  class Master < Mobilize::Box
    after_initialize :set_self
    def set_self;@box, @master = self, self;end

    def start
      @master.start_resque_web
    end

    def stop
      @master.stop_resque_web
    end

    def start_resque_web
      _redis                = Mobilize.config.redis
      _resque_auth_path     = "#{ @master.mobilize_config_dir }/resque-web-auth.rb"
      @master.sh              "resque-web #{ _resque_auth_path } -r #{ _redis.host }:#{ _redis.port }:0"
    end

    def stop_resque_web
      @master.sh              "ps aux | grep resque-web " +
                              "| awk '{print $2}' | xargs kill", false
    end

    def install
      @master.install_mobilize
      @master.install_resque_web_routing
      @master.write_resque_web_auth
    end

    def install_resque_web_routing
      #add iptables reroute for port 80, set iptables persistent
      @master.sh              "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 5678"
    end

    def write_resque_web_auth
      _config                    = Mobilize.config.cluster.master.resque_web

      _resque_web_auth_script    = "require 'yaml';Resque::Server.use(Rack::Auth::Basic) do |_user, _password|\n" +
                                   "[_user, _password] == ['#{ _config.username }', '#{ _config.password }']\n" +
                                   "end"

      @master.write                _resque_web_auth_script, "#{ @master.mobilize_config_dir }/resque-web-auth.rb"
      true
    end
  end
end
