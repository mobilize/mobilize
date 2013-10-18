module Mobilize
  class Box
    module Action
      module Write
        #take all envs that start with MOB and write them to a file on the engine
        def write_mobrc

          @box                  = self

          @mobrc_path           = @box.mobilize_config_dir + "/mobrc"

          @mob_envs             = ENV.select{|key,value|
                                              key.starts_with? "MOB"}

          @mobrc_string         = @mob_envs.map{|key,value|
                                                %{export #{key}=#{value}}
                                               }.join("\n")

          @box.write              @mobrc_string, @mobrc_path

          return true
        end
        def write_resque_pool

          @box                  = self

          @resque_pool_path     = @box.mobilize_config_dir + "/resque-pool.yml"

          @resque_pool_string   = {"test"=>{"mobilize-#{Mobilize.env}" => Mobilize.config.engine.workers}}.to_yaml

          @box.write              @resque_pool_string, @resque_pool_path

          return true
        end
        def write_keys

          @box    = self

          @box.cp   Config.key_dir, @box.key_dir

        end
        def write_god_file

          @box                  = self

          @samples_dir          = "#{Mobilize.root}/samples"

          @god_file_name        = "resque-pool-#{Mobilize.env}.rb"

          @box.cp                 "#{@samples_dir}/#{@god_file_name}", "#{@box.mobilize_config_dir}/#{@god_file_name}"
        end
      end
    end
  end
end
