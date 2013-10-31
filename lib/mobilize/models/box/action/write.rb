module Mobilize
  class Box
    module Action
      module Write
        #take all envs that start with MOB and write them to a file on the engine
        def write_mobrc

          _box                  = self
          _mobrc_path           = _box.mobilize_config_dir + "/mobrc"

          _mob_envs             = ENV.select{|_key, _value|
                                              _key.starts_with? "MOB"}

          _mobrc_string         = _mob_envs.map{|_key, _value|
                                                %{export #{_key}=#{_value}}
                                               }.join("\n")

          _box.write              _mobrc_string, _mobrc_path
          true
        end

        def write_resque_pool_file
          _box                  = self
          _resque_pool_path     = _box.mobilize_config_dir + "/resque-pool.yml"
          _resque_pool_string   = {"test"=>{"mobilize-#{Mobilize.env}" => Mobilize.config.engine.workers}}.to_yaml
          _box.write              _resque_pool_string, _resque_pool_path
          true
        end

        def write_resque_auth
          _box                       = self
          _config                    = Mobilize.config.resque

          _resque_auth_script        = "Resque::Server.use(Rack::Auth::Basic) do |_user, _password|\n" +
                                       "[_user, _password] == ['#{_config.username}', '#{_config.password}']\n" +
                                       "end"

          _box.write                   _resque_auth_script, "#{_box.mobilize_config_dir}/resque-auth.rb"
          true
        end

        def write_keys
          _box    = self
          _box.cp   Config.key_dir, _box.key_dir
        end

        def write_god_file
          _box                  = self
          _god_file_name        = "resque-pool-#{Mobilize.env}.rb"

          _box.cp                 "#{Mobilize.config_dir}/#{_god_file_name}", "#{_box.mobilize_config_dir}/#{_god_file_name}"
          true
        end
      end
    end
  end
end
