module Mobilize
  class Script < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :stdin,            type: String
    field :task_id,          type: String
    field :name,             type: String, default:->{ stdin.alphanunder[ 0..254 ] }
    field :_id,              type: String, default:->{ "script/#{ stdin.to_md5 }" }

    def write( _task )
      _script              = self
      _task.refresh_dir
      _stdin_path          = _task.dir + "/stdin"
      _stdin_path.write      _script.stdin
      Log.write              "stdin written to local dir", "INFO", _task
    end

    def Script.session
      "session"#placeholder
    end

    def run( _task )
      _script                 =  self
      _script.write              _task
      _task.gsub!
      #cd to job dir and execute file from there
      _run_cmd                = "(cd #{ _task.dir }/ && sh stdin) > " +
                                "#{ _task.dir }/stdout 2> " +
                                "#{ _task.dir }/stderr; " +
                                "touch #{ _task.dir }/log; " +
                                "echo $? > #{ _task.dir }/exit_signal"
      _run_cmd.popen4

      _streams                =  _script.streams _task
      if                         _streams[ :exit_signal ].strip != "0"
        Log.write                _streams[ :stderr ], "FATAL"
      end
      Log.write                  "run complete", "INFO", _script
    end

    def streams( _task )
      _stream_array         = [ :stdin, :stdout, :stderr, :exit_signal, :log ]

      _result               = {}
      _stream_array.each      {|_stream|
                                _value              = File.read "#{ _task.dir }/#{ _stream.to_s }"
                                _result[ _stream ]  = _value
                              }

      _result
    end
  end
end
