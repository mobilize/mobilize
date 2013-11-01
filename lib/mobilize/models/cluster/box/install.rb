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

        def apt_install(_name, _version)
          _box                   = self
          Log.write                "Installing apt #{_name} #{_version}..."
          _box.sh                  "sudo apt-get install -y #{_name}=#{_version}"
        end

        def install_ruby
          _box            = self
          _box.install      '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3',
                            "Installing RVM and Ruby 1.9.3 on #{_box.id}"
        end

        def install_mobilize_gem(_path = "mobilize/mobilize")
          _box                         = self
          _box.sh                        "rm -rf mobilize && " +
                                         "git clone http://u:p@github.com/#{_path}.git --depth=1"
          _repo_revision               = _box.sh "cd mobilize && git log -1 --pretty=format:%H"
          _installed_revision          = begin; _box.sh "mob revision";rescue;nil;end
          if _installed_revision      != _repo_revision
            Log.write                    "Installing Mobilize on #{_box.id}\n" +
                                         "installed revision: #{_installed_revision.to_s}\n" +
                                         "repo revision: #{_repo_revision}"
            _box.sh                      "cd mobilize && bundle install && rake install"
          else
             Log.write                   "mobilize revision #{_installed_revision} already installed on #{_box.id}"
          end
          _box.sh                        "rm -rf mobilize"
        end

        def install_mobilize
          _box                       = self
          _box.install_ruby
          _box.install_git
          _box.install_redis

          _box.write_mobrc
          _box.write_keys

          _box.install_mobilize_gem
        end

        def install_git
          _box                    = self
          _box.apt_install          "git", "1:1.7.9.5-1"
        end

        def install_redis

          _box                   =  self
          _box.apt_install         "redis-server", "2:2.2.12-1build1"
          #installation starts redis-server for some reason so stop it
          _box.sh                  "ps aux | grep redis-server | awk '{print $2}' | " +
                                   "(sudo xargs kill)", false
          return true
        end
      end
    end
  end
end
