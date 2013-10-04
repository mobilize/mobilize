#use run after opening a session to
#get a proper reading of stderr, exit code, exit signal
#adapted from http://stackoverflow.com/questions/3386233/how-to-get-exit-status-with-rubys-netssh-library
module Net
  module SSH
    module Connection
      class Session
        #except=true means exception will be raised on exit_code != 0
        def run(command, except=true)
          @ssh        = self
          stdout_data = ""
          stderr_data = ""
          exit_code   = nil
          exit_signal = nil
          @ssh.open_channel do |channel|
            channel.exec(command) do |ch, success|
              unless success
                abort "FAILED: couldn't execute command (ssh.channel.exec)"
              end
              channel.on_data do |ch_d,data|
                stdout_data+=data
                Mobilize::Logger.info("[stdout]: #{data}") if Mobilize.config.log.level=="debug"
              end

              channel.on_extended_data do |ch_ed,type,data|
                stderr_data+=data
                Mobilize::Logger.info("[stderr]: #{data}") if Mobilize.config.log.level=="debug"
              end

              channel.on_request("exit-status") do |ch_exst,data|
                exit_code = data.read_long
              end

              channel.on_request("exit-signal") do |ch_exsig, data|
                exit_signal = data.read_long
              end
            end
          end
          @ssh.loop
          result            = {
                               stdout: stdout_data,
                               stderr: stderr_data,
                               exit_code: exit_code,
                               exit_signal: exit_signal
                              }
          if except and exit_code!=0
            Mobilize::Logger.error stderr_data
          else
            return result
          end
        end
      end
    end
  end
end
