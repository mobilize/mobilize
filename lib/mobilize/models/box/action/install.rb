module Mobilize
  class Box
    module Action
      module Install

        def install(script, message = nil)

          @box, @message, @script   = self, message, script

          Logger.info(@message)    if @message

          @box.sh                     @script

          return true

        end

        def install_rvm

          @box            = self

          @box.install      '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3',

            "Installing RVM and Ruby 1.9.3 on #{@box.id}"

        end

        def install_git

          @box            = self

          @box.install      "sudo apt-get install -y git",

            "Installing git on #{@box.id}"

        end

        def install_mobilize_gem(path = "mobilize/mobilize")

          @box                   = self

          @install_script        = "rm -rf mobilize && " +
                                   "git clone http://u:p@github.com/#{path}.git --depth=1 && " +
                                   "cd mobilize && bundle install && rake install"

          @box.install             @install_script, "Installing Mobilize on #{@box.id}"

          @box.sh                  "rm -rf mobilize"

        end

        def install_god

          @box                   = self

          @install_cmd           = "gem install god"

          @box.sh                  @install_cmd

        end

        def install_mobilize

          @box                       = self

          @box.find_or_create_instance Box.session

          @box.install_rvm

          @box.install_git

          @box.install_redis_server

          @box.write_mobrc

          @box.write_keys

          @box.install_mobilize_gem

        end

        def install_redis_server

          @box                   = self

          @box.install             "sudo apt-get install -y redis-server",
                                   "Installing redis-server on #{@box.id}"

          #installation starts redis-server for some reason so stop it
          @box.sh                  "ps aux | grep redis-server | awk '{print $2}' | " +
                                   "(sudo xargs kill)", false
          return true
        end
      end
    end
  end
end
