module Mobilize
  class Box
    module Action
      module Start
        def start_engine

          _box                           = self

          _box.install_mobilize

          _box.write_resque_pool

          _box.upload_god_file

          _box.start_god

          _box.load_god_file

        end

        def start_god_file

          _box                  = self

          _god_file_name        = "resque-pool-#{Mobilize.env}.rb"

          _box.sh                 "god && god load #{_box.mobilize_config_dir}/#{_god_file_name}"

        end
      end
    end
  end
end
