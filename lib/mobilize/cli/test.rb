require 'mobilize'
module Mobilize
  module Cli
    module Test
      def Test.perform( _args )
        Mongoid.purge!
        Dir.chdir Mobilize.root
        "git init".popen4
        _operator        = _args[ 1 ]
        _test_model_dir  = "#{ Mobilize.root }/test/models"
        _all_test_paths  = Dir.glob "#{ _test_model_dir }/*.rb"
        if _operator    == "all"
          _test_paths    = _all_test_paths
        else
          _test_names    = _operator.split_strip ","
          _test_paths    = _all_test_paths.select { |_test|
                                                     _base_name         = _test.basename.split( '_' ).first
                                                     _test_names.include? _base_name
                                                  }
        end
        _threads         = _test_paths.map { |_test_path|
                             Proc.new {
                               _result = "m #{ _test_path }".popen4( false )
                               puts "#{ _test_path.basename }\n#{ _result }"
                               _result
                                      } }
        _results         = _threads.thread
        _results.each do  |_result|
          _last_line = _result.split( "\n" ).last
          _fields    = _last_line.split_strip ","
          _failures  = _fields[ -3 ].split(" ").first.to_i
          _errors    = _fields[ -2 ].split(" ").first.to_i
          raise "One or more tests have failed or errored!" if _errors >= 1 or _failures >= 1
        end
      end
    end
  end
end
