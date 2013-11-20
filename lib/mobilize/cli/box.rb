require 'mobilize'
require 'optparse'
module Mobilize
  module Cli
    module Box
      def Box.banner_row
        "box - run commands and install packages on cluster boxes"
      end
      def Box.perform
        _operator                       = ARGV.shift

        if ARGV.length == 1
           _box_name    = ARGV.shift
        else 
           _operand     = ARGV.shift
           _box_name    = ARGV.shift
        end

        _box            = Box.find_or_create_by_name _box_name

        begin
          if _operand
            _result                       = _box.send _operator, _operand
          else
            _result                       = _box.send _operator
          end
          puts                            _result
        rescue
          _box.send                       [ _operator, _operand ].compact.join "_"
        end
      end
    end
  end
end
