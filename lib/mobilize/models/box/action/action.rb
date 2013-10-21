module Mobilize
  class Box
    module Action
      include Mobilize::Box::Action::Install
      include Mobilize::Box::Action::Write
      extend ActiveSupport::Concern
      included do
        field      :user_name,        type: String, default:->{Mobilize.config.box.user_name}
        field      :home_dir,         type: String, default:->{"/home/#{user_name}"}
      end

      def mobilize_home_dir;        "#{self.home_dir}/.mobilize";end

      def mobilize_config_dir;      "#{self.mobilize_home_dir}/config";end

      def key_dir;                  "#{self.mobilize_home_dir}/keys";end

      def ssh_cmd

        _box                      = self
        _ssh_cmd                  = "ssh -i #{Box.private_key_path} " +
                                    "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                    "#{_box.user_name}@#{_box.dns}"
        puts                        _ssh_cmd

      end

      def sh(command,  except = true, streams = [:stdout, :stderr])

        _box                                  = self

        _ssh_args                             = {keys: [Box.private_key_path],
                                                 paranoid: false}

        _command_file_path                    = "/tmp/" + "#{command}#{Time.now.utc.to_f.to_s}".to_md5

        _box.write                              command, _command_file_path, false, false

        send_args                             = ["start", _box.dns, _box.user_name, _ssh_args]

        _result                               = Net::SSH.send_w_retries(*send_args) do |ssh|
                                                  ssh.run("bash -l -c 'sh #{_command_file_path}'", except, streams)
                                                end

        Net::SSH.send_w_retries(*send_args)   {|ssh| ssh.run "rm #{_command_file_path}"}

        _result

      end

      def cp(loc_path, rem_path, mkdir = true, log = true)

        _box, _loc_path, _rem_path = self, loc_path, rem_path

        _box.sh(                     "mkdir -p " + File.dirname(_rem_path)) if mkdir

        _ssh_args                  = {keys: [Box.private_key_path],
                                      paranoid: false}

        send_args                  = ["start", _box.dns, _box.user_name, _ssh_args]

        _result                    = Net::SCP.send_w_retries(*send_args) do |scp|
                                       scp.upload!(_loc_path, _rem_path, recursive: true) do |ch, name, sent, total|
                                         Logger.write("#{name}: #{sent}/#{total}") if log
                                       end
                                     end

        _result

      end

      def write(string, rem_path, mkdir = true, log = true)

        _box                      = self

        _string, _rem_path        = string, rem_path

        _temp_file_path           = "/tmp/" + "#{string}#{Time.now.utc.to_f.to_s}".to_md5

        begin
          File.write                _temp_file_path, _string
          _box.cp                   _temp_file_path, _rem_path, mkdir, false
        ensure
          FileUtils.rm              _temp_file_path, force: true
        end

        Logger.write                "Wrote: #{_string.ellipsize(25)} to #{_box.id}:#{_rem_path}" if log

      end

      def start_engine

        _box                  = self

        _god_file_name        = "resque-pool-#{Mobilize.env}.rb"

        _start_cmd            = "god && god load #{_box.mobilize_config_dir}/#{_god_file_name}"

        _box.sh                 _start_cmd

        Logger.write            _start_cmd

        true

      end

      def stop_engine
        _box                  = self

        _box.sh                 "god stop resque-pool-#{Mobilize.env}"

        _pid_path             = "#{_box.mobilize_home_dir}/pid/resque-pool-#{Mobilize.env}.pid"

        _box.sh                 "kill -2 `cat #{_pid_path}`", false

      end
    end
  end
end
