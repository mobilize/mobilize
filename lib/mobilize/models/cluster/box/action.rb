module Mobilize
  class Box
    module Action
      def view_ssh_cmd
        _box                      = self
        _ssh_cmd                  = "ssh -i #{Box.private_key_path} " +
                                    "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                    "#{_box.user_name}@#{_box.dns}"
        puts                        _ssh_cmd
      end

      def sh( _command,  _except = true, _streams = :stdout )
        _box                                  = self
        _ssh_args                             = { keys: [ Box.private_key_path ],
                                                  paranoid: false }
        _command_file_path                    = "/tmp/" + "#{ _command }#{ Time.now.utc.to_f.to_s }".to_md5
        _box.write                              _command, _command_file_path, false, false
        _send_args                            = [ "start", _box.dns, _box.user_name, _ssh_args ]
        _result                               = Net::SSH.send_w_retries( *_send_args ) do |_ssh|
                                                  _ssh.run _box.name, "bash -l -c 'sh #{ _command_file_path }'",
                                                           _except, [ _streams ].flatten
                                                end
        Net::SSH.send_w_retries( *_send_args ) { |_ssh| _ssh.run _box.name, "rm #{_command_file_path}" }

        if _streams == :stdout;_result[:stdout];else;_result;end
      end

      def cp( _loc_path, _rem_path, _mkdir = true, _log = true )
        _box                       = self
        _box.sh(                     "mkdir -p " + _rem_path.dirname ) if _mkdir
        _ssh_args                  = { keys: [ Box.private_key_path ],
                                       paranoid: false }
        _send_args                 = [ "start", _box.dns, _box.user_name, _ssh_args ]
        _result                    = Net::SCP.send_w_retries( *_send_args ) do |_scp|
                                       _scp.upload!( _loc_path, _rem_path, recursive: true ) do |_ch, _name, _sent, _total|
                                       Log.write( "#{ _name.basename } -> #{ _box.name }: #{ _sent }/#{ _total }" ) if _log
                                       end
                                     end
        _result
      end

      def write( _string, _rem_path, _mkdir = true, _log = true )
        _box                      = self
        _temp_file_path           = "/tmp/" + "#{ _string }#{ Time.now.utc.to_f.to_s }".to_md5
        begin
          File.write                _temp_file_path, _string
          _box.cp                   _temp_file_path, _rem_path, _mkdir, false
        ensure
          FileUtils.rm              _temp_file_path, force: true
        end
        Log.write                   "Wrote: #{ _string.ellipsize 25 } to #{ _box.id }:#{ _rem_path }" if _log
      end

      def write_mobrc
        _box                  = self
        _mobrc_path           = _box.mobilize_config_dir + "/mobrc"

        _mob_envs             = ENV.select { |_key, _value|
                                              _key.starts_with? "MOB" }

        _mobrc_string         = _mob_envs.map { |_key, _value|
                                              %{export #{ _key }=#{ _value }}
                                              }.join "\n"

        _box.write              _mobrc_string, _mobrc_path
        true
      end

      def write_keys
        _box    = self
        _box.cp   Config.key_dir, _box.key_dir
      end

      def terminate( _session = Box.session )
        #terminates the remote then
        #deletes the local database version
        _box                          = self

        if _box.remote_id
          _session.terminate_instances  _box.remote_id
          Log.write                     "Terminated remote #{_box.remote_id} for #{_box.id}"
        end

        _box.delete
        Log.write                       "Deleted #{_box.id} from DB"

        true
      end

      def launch( _session = Box.session )

        _box                         = self

        _remote_params               = {key_name:      _box.keypair_name,
                                        group_ids:     _box.security_groups,
                                        instance_type:   _box.size}

        _remotes                     = _session.launch_instances(_box.ami, _remote_params)
        _remote                      = _remotes.first

        _box.update_attributes         remote_id: _remote[:aws_instance_id]
        _session.create_tag            _box.remote_id, "Name", _box.name
        _remote                      = _box.wait_for_running _session
        _box.sync                      _remote
      end

      def wait_for_running (_session  = Box.session )
        _box                          = self
        _remote                       = _box.remote _session
        while                           _remote[:aws_state] != "running"
          Log.write                     "remote #{_box.remote_id} still at #{_remote[:aws_state]} -- waiting 10 sec"
          sleep                         10
          _remote                     = _box.remote _session
        end
        Log.write                     "remote #{_box.remote_id} online -- waiting 20 sec for SSH ready"
        sleep                         20
        _remote
      end

      def apt_install( _name, _version )
        _box                   = self
        Log.write                "Installing apt #{ _name } #{ _version }..."
        _box.sh                  "sudo apt-get install -y #{ _name }=#{ _version }"
      end

      def install_ruby
        _box            = self
        _box.sh           '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3'
      end

      def install_mobilize_gem( _path = "mobilize/mobilize" )
        _box                          = self
        _box.sh                         "rm -rf mobilize && " +
                                        "git clone http://u:p@github.com/#{ _path }.git --depth=1"
        _repo_revision                = _box.sh "cd mobilize && git log -1 --pretty=format:%H"
        _installed_revision           = begin; _box.sh "mob revision";rescue;nil;end
        if _installed_revision       != _repo_revision
          Log.write                     "Installing Mobilize on #{ _box.id }\n" +
                                        "installed revision: #{ _installed_revision.to_s }\n" +
                                        "repo revision: #{ _repo_revision }"
          _box.sh                       "cd mobilize && bundle install && rake install"
        else
           Log.write                    "mobilize revision #{ _installed_revision } already installed on #{ _box.id }"
        end
        _box.sh                         "rm -rf mobilize"
      end

      def install_mobilize
        _box                          = self
        _box.install_ruby
        _box.install_git
        _box.install_redis

        _box.write_mobrc
        _box.write_keys

        _box.install_mobilize_gem
      end

      def install_git
        _box                          = self
        _box.apt_install               "git", "1:1.7.9.5-1"
      end

      def install_redis

        _box                          = self
        _box.apt_install                "redis-server", "2:2.2.12-1build1"
        #installation starts redis-server for some reason so stop it
        _box.sh                         "ps aux | grep redis-server | awk '{print $2}' | " +
                                        "(sudo xargs kill)", false
        true
      end
    end
  end
end
