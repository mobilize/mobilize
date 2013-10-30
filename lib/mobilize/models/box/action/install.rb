module Mobilize
  class Box
    module Action
      module Install

        def install(_script, _message = nil)
          _box                      = self
          Log.write(_message)      if _message
          _box.sh                     _script
          return true
        end

        def install_rvm
          _box            = self
          _box.install      '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3',
                            "Installing RVM and Ruby 1.9.3 on #{_box.id}"
        end

        def install_git
          _box            = self
          _box.install      "sudo apt-get install -y git", "Installing git on #{_box.id}"
        end

        def install_mobilize_gem(_path = "c4ssio/mobilize")
          _box                         = self
          _clone_script                = "rm -rf mobilize && " +
                                         "git clone http://u:p@github.com/#{_path}.git --depth=1"
          _box.sh                        _clone_script
          _repo_revision               = "cd mobilize && git log -1 --pretty=format:%H"
          _installed_revision          = begin; _box.sh "mob revision";rescue;nil;end
          if _installed_revision      != _repo_revision
             _install_script           = "cd mobilize && bundle install && rake install"
             _box.install                _install_script, "Installing Mobilize on #{_box.id}"
          else
             Log.write                   "mobilize revision #{_installed_revision} already installed on #{_box.id}"
          end
          _box.sh                  "rm -rf mobilize"
        end

        def install_god
          _box                   = self
          _box.install            "gem install god", "Installing god on #{_box.id}"
        end

        def install_resque_pool
          _box                   = self
          _box.install             "gem install resque && gem install resque-pool",
                                   "Installing resque && resque-pool on #{_box.id}"
          #resque-pool requires a git repo to work for some reason
          _box.sh                  "cd `mob test root` && git init"
        end

        def install_engine
          _box                           = self
          _box.install_mobilize
          _box.install_resque_pool

          _box.write_resque_pool_file
          _box.write_god_file

          _box.install_god
        end

        def install_master
          _box                           = self
          _box.install_mobilize
        end

        def install_resque_web
          _box                       = self
          _box.install                 "gem install resque", "Installing resque on #{_box.id}"
          #add iptables reroute for port 80, set iptables persistent
          _box.sh "(sudo iptables -t nat -A " +
                  "PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 5678) && " +
                  "(sudo apt-get install -y iptables-persistent)"
        end

        def install_mobilize
          _box                       = self
          _box.install_rvm
          _box.install_git
          _box.install_redis_server

          _box.write_mobrc
          _box.write_keys

          _box.install_mobilize_gem
        end

        def install_redis_server

          _box                   = self
          _box.install             "sudo apt-get install -y redis-server",
                                   "Installing redis-server on #{_box.id}"
          #installation starts redis-server for some reason so stop it
          _box.sh                  "ps aux | grep redis-server | awk '{print $2}' | " +
                                   "(sudo xargs kill)", false
          return true
        end
      end
    end
  end
end
