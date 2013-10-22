module Mobilize
  module Cli
    module Box
      def Box.install(_service, _box_name, _opts = {})
        _box           = Box.find_by name: _box_name
        
        _box.send
      end
      def Box.write(_service, _box_name, _opts = {})

      end
      def Box.start(_service, _box_name)

      end
      def Box.stop(_service, _box_name)

      end
      def Box.terminate(_box_name)

      end
      def Box.launch(_box_name)

      end
    end
  end
end
