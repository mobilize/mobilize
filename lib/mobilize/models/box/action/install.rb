module Mobilize
  class Box
    module Action
      module Install

        def install(script, message = nil)

          _box, _message, _script   = self, message, script

          Logger.write(_message)   if _message

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

          _box.install      "sudo apt-get install -y git",

            "Installing git on #{_box.id}"

        end

        def install_mobilize_gem(path = "mobilize/mobilize")

          _box                   = self

          _install_script        = "rm -rf mobilize && " +
                                   "git clone http://u:p@github.com/#{path}.git --depth=1 && " +
                                   "cd mobilize && bundle install && rake install"

          _box.install             _install_script, "Installing Mobilize on #{_box.id}"

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
          _box.sh                  "cd #{Mobilize.root} && git init"
        end

        def install_engine

          _box                           = self

          _box.install_mobilize

          _box.install_resque_pool

          _box.write_resque_pool_file

          _box.write_god_file

          _box.install_god

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
