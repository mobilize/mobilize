#use run after opening a session to
#get a proper reading of stderr, exit code, exit signal
#adapted from http://stackoverflow.com/questions/3386233/how-to-get-exit-status-with-rubys-netssh-library
module Net
  module SSH
    module Connection
      class Session
        #except=true means exception will be raised on exit_code != 0
        def run(_command, _except = true, _streams = [ :stdout, :stderr ])

          _ssh, @stdout_data, @stderr_data    = self, "", ""
          @exit_code, @exit_signal, @streams  = nil, nil, _streams

          @command                            = _command

          _ssh.open_channel                 do |_channel|
            _ssh.run_proc _channel
          end
          _ssh.loop

          if                                    _except and @exit_code!=0
            Mobilize::Logger.write              @stderr_data, "FATAL"
          else
            _result                           = {  stdout:      @stdout_data,
                                                   stderr:      @stderr_data,
                                                   exit_code:   @exit_code,
                                                   exit_signal: @exit_signal  }
            _result
          end
        end
        def run_proc(_channel)
          _ssh                     = self
          _channel.exec(@command) do |_ch, _success|
            unless                            _success
              Mobilize::Logger.write          "FAILED: couldn't execute command (ssh.channel.exec)", "FATAL"
            end
            _channel.on_data                  do |_ch_d, _data|
              @stdout_data                    +=  _data
              _ssh.log_stream                     :stdout, _data
            end

            _channel.on_extended_data         do |_ch_ed, _type, _data|
              @stderr_data                    +=  _data
              _ssh.log_stream                     :stderr, _data
            end

            _channel.on_request("exit-status") do |_ch_exst, _data|
              @exit_code                        = _data.read_long
            end

            _channel.on_request("exit-signal") do |_ch_exsig, _data|
              @exit_signal                     = _data.read_long
            end
          end
        end
        def log_stream(_stream, _data)
          Mobilize::Logger.write("#{_stream.to_s}: #{_data}")  if @streams.include?(_stream)
        end
      end
    end
  end
end
