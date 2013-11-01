module Mobilize
  class Box
    module Action
      include Mobilize::Box::Action::Install

      def user_name;                 Mobilize.config.box.user_name;end

      def home_dir;                  "/home/#{self.user_name}";end

      def mobilize_home_dir;        "#{self.home_dir}/.mobilize";end

      def mobilize_config_dir;      "#{self.mobilize_home_dir}/config";end

      def key_dir;                  "#{self.mobilize_home_dir}/keys";end

      def view_ssh_cmd
        _box                      = self
        _ssh_cmd                  = "ssh -i #{Box.private_key_path} " +
                                    "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                    "#{_box.user_name}@#{_box.dns}"
        puts                        _ssh_cmd
      end

      def sh(_command,  _except = true, _streams = :stdout)
        _box                                  = self
        _ssh_args                             = {keys: [Box.private_key_path],
                                                 paranoid: false}
        _command_file_path                    = "/tmp/" + "#{_command}#{Time.now.utc.to_f.to_s}".to_md5
        _box.write                              _command, _command_file_path, false, false
        _send_args                             = ["start", _box.dns, _box.user_name, _ssh_args]
        _result                               = Net::SSH.send_w_retries(*_send_args) do |_ssh|
                                                  _ssh.run("bash -l -c 'sh #{_command_file_path}'", _except, [_streams].flatten)
                                                end
        Net::SSH.send_w_retries(*_send_args)   {|_ssh| _ssh.run "rm #{_command_file_path}"}

        if _streams == :stdout;_result[:stdout];else;_result;end
      end

      def cp(_loc_path, _rem_path, _mkdir = true, _log = true)
        _box                       = self
        _box.sh(                     "mkdir -p " + File.dirname(_rem_path)) if _mkdir
        _ssh_args                  = {keys: [Box.private_key_path],
                                      paranoid: false}
        _send_args                 = ["start", _box.dns, _box.user_name, _ssh_args]
        _result                    = Net::SCP.send_w_retries(*_send_args) do |scp|
                                       scp.upload!(_loc_path, _rem_path, recursive: true) do |_ch, _name, _sent, _total|
                                         Log.write("#{_name}: #{_sent}/#{_total}") if _log
                                       end
                                     end
        _result
      end

      def write(_string, _rem_path, _mkdir = true, _log = true)
        _box                      = self
        _temp_file_path           = "/tmp/" + "#{_string}#{Time.now.utc.to_f.to_s}".to_md5
        begin
          File.write                _temp_file_path, _string
          _box.cp                   _temp_file_path, _rem_path, _mkdir, false
        ensure
          FileUtils.rm              _temp_file_path, force: true
        end
        Log.write                   "Wrote: #{_string.ellipsize(25)} to #{_box.id}:#{_rem_path}" if _log
      end

      def write_mobrc
        _box                  = self
        _mobrc_path           = _box.mobilize_config_dir + "/mobrc"

        _mob_envs             = ENV.select{|_key, _value|
                                            _key.starts_with? "MOB"}

        _mobrc_string         = _mob_envs.map{|_key, _value|
                                              %{export #{_key}=#{_value}}
                                             }.join("\n")

        _box.write              _mobrc_string, _mobrc_path
        true
      end

      def write_keys
        _box    = self
        _box.cp   Config.key_dir, _box.key_dir
      end
    end
  end
end
