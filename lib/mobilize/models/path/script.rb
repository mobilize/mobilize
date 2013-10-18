module Mobilize
  class Script < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :stdin,            type: String
    field :task_id,          type: String
    field :name,             type: String, default:->{ stdin.alphanunderscore[0..254] }
    field :_id,              type: String, default:->{"script/#{stdin.to_md5}"}

    def write(task)
      @task              = task
      @task.refresh_dir
      @stdin_path        = @task.dir + "/stdin"
      @file              = File.open @stdin_path, "w"
      @file.print          @script.stdin
      @file.close
      Logger.write         "wrote stdin into task dir at #{@stdin_path}"
    end

    def Script.session
      "session"#placeholder
    end

    def run(task)
      @script                 =  self
      @task                   =  task
      @script.write              @task
      @task.gsub!
      #cd to job dir and execute file from there
      @run_cmd                = "(cd #{@task.dir}/ && sh stdin) > " +
                                "#{@task.dir}/stdout 2> " +
                                "#{@task.dir}/stderr; " +
                                "touch #{@task.dir}/log; " +
                                "echo $? > #{@task.dir}/exit_signal"
      @run_cmd.popen4

      @streams                =  @script.streams @task
      if                         @streams[:exit_signal].strip != "0"
        Logger.write             @streams[:stderr], "FATAL"
      end
    end

    def streams(task)
      @script               = self
      @task                 = task
      @stream_array         = [:stdin, :stdout, :stderr, :exit_signal, :log]

      @result               = {}
      @stream_array.each      {|stream|
                                value           = File.read "#{@task.dir}/#{stream.to_s}"
                                @result[stream] = value
                              }

      return                  @result
    end
  end
end
