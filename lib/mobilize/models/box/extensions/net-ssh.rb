#use run after opening a session to
#get a proper reading of stderr, exit code, exit signal
#adapted from http://stackoverflow.com/questions/3386233/how-to-get-exit-status-with-rubys-netssh-library
module Net
  module SSH
    module Connection
      class Session
        #except=true means exception will be raised on exit_code != 0
        def run(command, except=true, streams = [ :stdout, :stderr ])

          @ssh, @stdout_data, @stderr_data    = self, "", ""
          @exit_code, @exit_signal, @streams  = nil, nil, streams

          @command, @except                   = command, except

          @ssh.open_channel                 do |channel|
            @ssh.run_proc(channel)
          end
          @ssh.loop

          if                                    @except and @exit_code!=0
            Mobilize::Logger.error              @stderr_data
          else
            @result                           = {  stdout:      @stdout_data,
                                                   stderr:      @stderr_data,
                                                   exit_code:   @exit_code,
                                                   exit_signal: @exit_signal  }
            return                              @result
          end
        end
        def run_proc(channel)
          @ssh                     = self
          channel.exec(@command) do |ch, success|
            unless                            success
              Mobilize::Logger.error          "FAILED: couldn't execute command (ssh.channel.exec)"
            end
            channel.on_data                   do |ch_d,data|
              @stdout_data                    += data
              @ssh.log_stream                    :stdout, data
            end

            channel.on_extended_data          do |ch_ed,type,data|
              @stderr_data                    += data
              @ssh.log_stream                    :stderr, data
            end

            channel.on_request("exit-status") do |ch_exst,data|
              @exit_code                       = data.read_long
            end

            channel.on_request("exit-signal") do |ch_exsig, data|
              @exit_signal                     = data.read_long
            end
          end
        end
        def log_stream(stream,data)
          Mobilize::Logger.info("#{stream.to_s}: #{data}")  if @streams.include?(stream)
        end
      end
    end
  end
end
