module Mobilize
  module Ssh
    include Mongoid::Document
    include Mongoid::Timestamps
    extend ActiveSupport::Concern
    included do
      field      :user_name,        type: String, default:->{Mobilize.config.box.user_name}
      field      :home_dir,         type: String, default:->{"/home/#{user_name}"}
    end

    def mobilize_dir;             "#{self.home_dir}/.mobilize";end

    def config_dir;               "#{self.mobilize_dir}/config";end

    def key_dir;                  "#{self.mobilize_dir}/keys";end

    def Box.private_key_path;     "#{Mobilize.home_dir}/keys/box.ssh"; end #created during configuration


    def ssh_cmd
      @box                      = self
      @ssh_cmd                  = "ssh -i #{Box.private_key_path} " +
                                  "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                  "#{@box.user_name}@#{@box.dns}"
      return                      @ssh_cmd
    end

    def sh(command,  except = true, streams=[:stdout, :stderr])
      @box                      = self
      @ssh_args                 = {keys: [Box.private_key_path],
                                   paranoid: false}

      send_args                 = ["start", @box.dns, @box.user_name, @ssh_args]
      @result                   = Net::SSH.send_w_retries(*send_args) do |ssh|
                                    ssh.run(command, except, streams)
                                  end
      return                      @result
    end

    def cp(loc_path, rem_path)
      @box, @loc_path, @rem_path = self, loc_path, rem_path

      @box.sh                      "mkdir -p " + File.dirname(@rem_path)
      @ssh_args                  = {keys: [Box.private_key_path],
                                    paranoid: false}
      send_args                  = ["start",@box.dns,@box.user_name,@ssh_args]

      @result                    = Net::SCP.send_w_retries(*send_args) do |scp|
                                     scp.upload!(loc_path,rem_path, recursive: true) do |ch, name, sent, total|
                                       Logger.info "#{name}: #{sent}/#{total}"
                                     end
                                   end
      return                       @result
    end

    def write(string, rem_path)
      @box                      = self
      @string, @rem_path        = string, rem_path
      @file                     = Tempfile.new 'box_write'
      begin
        @file.write               @string
        @file.close
        @box.cp                   @file.path, @rem_path
      ensure
        @file.close unless @file.closed?
        @file.unlink
      end
      Logger.info                 "Wrote string #{@string.ellipsize(10)} to #{@box.id}:#{@rem_path}"
    end
  end
end
