module Mobilize
  class Box
    module Action
      module Start
        def start_engine

          @box                           = self

          @box.install_mobilize

          @box.write_resque_pool

          @box.upload_god_file

          @box.start_god

          @box.load_god_file

        end

        def start_god_file

          @box                  = self

          @god_file_name        = "resque-pool-#{Mobilize.env}.rb"

          @box.sh                 "god && god load #{@box.mobilize_config_dir}/#{@god_file_name}"

        end
      end
    end
  end
end
