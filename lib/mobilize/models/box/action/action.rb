module Mobilize
  class Box
    module Action
      include Mobilize::Box::Action::Install
      include Mobilize::Box::Action::Write
      include Mobilize::Box::Action::Start
      extend ActiveSupport::Concern
      included do
        field      :user_name,        type: String, default:->{Mobilize.config.box.user_name}
        field      :home_dir,         type: String, default:->{"/home/#{user_name}"}
      end

      def mobilize_dir;             "#{self.home_dir}/.mobilize";end

      def mobilize_config_dir;      "#{self.mobilize_dir}/config";end

      def key_dir;                  "#{self.mobilize_dir}/keys";end

      def ssh_cmd

        @box                      = self
        @ssh_cmd                  = "ssh -i #{Box.private_key_path} " +
                                    "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                    "#{@box.user_name}@#{@box.dns}"
        puts                        @ssh_cmd

      end

      def sh(command,  except = true, streams = [:stdout, :stderr])

        @box                                  = self

        @ssh_args                             = {keys: [Box.private_key_path],
                                                 paranoid: false}

        @command_file_path                    = "/tmp/" + "#{command}#{Time.now.utc.to_f.to_s}".to_md5

        @box.write                              command, @command_file_path, false, false

        send_args                             = ["start", @box.dns, @box.user_name, @ssh_args]

        @result                               = Net::SSH.send_w_retries(*send_args) do |ssh|
                                                  ssh.run("bash -l -c 'sh #{@command_file_path}'", except, streams)
                                                end

        Net::SSH.send_w_retries(*send_args)   {|ssh| ssh.run "rm #{@command_file_path}"}

        return                                 @result

      end

      def cp(loc_path, rem_path, mkdir = true, log = true)

        @box, @loc_path, @rem_path = self, loc_path, rem_path

        @box.sh(                     "mkdir -p " + File.dirname(@rem_path)) if mkdir

        @ssh_args                  = {keys: [Box.private_key_path],
                                      paranoid: false}

        send_args                  = ["start",@box.dns,@box.user_name,@ssh_args]

        @result                    = Net::SCP.send_w_retries(*send_args) do |scp|
                                       scp.upload!(loc_path,rem_path, recursive: true) do |ch, name, sent, total|
                                         Logger.info("#{name}: #{sent}/#{total}") if log
                                       end
                                     end

        return                       @result

      end

      def write(string, rem_path, mkdir = true, log = true)

        @box                      = self

        @string, @rem_path        = string, rem_path

        @temp_file_path           = "/tmp/" + "#{string}#{Time.now.utc.to_f.to_s}".to_md5

        begin
          File.write                @temp_file_path, @string
          @box.cp                   @temp_file_path, @rem_path, mkdir, false
        ensure
          FileUtils.rm              @temp_file_path, force: true
        end

        Logger.info                 "Wrote: #{@string.ellipsize(25)} to #{@box.id}:#{@rem_path}" if log

      end
    end
  end
end
