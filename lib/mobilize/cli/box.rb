require 'mobilize'
require 'optparse'
module Mobilize
  module Cli
    module Box
      def Box.perform(_args)
        _operator                       = _args[1]
        _operand, _box_name             = _operator == "terminate" ? [ nil, _args[2].dup ] : [ _args[2], _args[3].dup ]

        _box                              = Box.find _box_name, _args

        return false unless _box
        _box.send                           [_operator, _operand].compact.join("_")
      end
      private

      def Box.find(_name, _args)
        _launch, _box, _Box        = false, nil, Mobilize::Box
        _opt_parser                = OptionParser.new do |_opts|
          _launch_args             = ['-l', '--launch', 'Launch box if not existing']
          _opts.on(*_launch_args) do
            _launch                = true
          end
        end
        _opt_parser.parse!           _args

        begin; _box                  = _Box.find_by name: _name; rescue;

          if   _launch or _args[2] == "launch"
               _box                  = _Box.find_or_create_by_name _name
          else
               Logger.write            "Box #{_name} not found; specify --launch to launch new"
               return false
          end
        end
        _box
      end
    end
  end
end
