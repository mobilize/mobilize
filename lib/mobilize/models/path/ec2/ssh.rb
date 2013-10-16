module Mobilize
  class Ssh
    include Mongoid::Document
    include Mongoid::Timestamps
    field      :private_key_path, type: String, default:->{Mobilize.config.ssh.private_key_path}
    field      :user_name,        type: String, default:->{Mobilize.config.ssh.user_name}
    field      :home_dir,         type: String, default:->{"/home/#{user_name}"}
    belongs_to :ec2

    def shell_cmd
      @ssh                 = self
      @ssh_cmd             = "ssh -i #{@ssh.private_key_path} #{@ssh.user_name}@#{@ssh.dns}"
      Logger.info            "Log in with: #{@ssh_cmd}"
      return true
    end

    def sh(command,  except =  true)
      @ssh                  =  self
      @ssh_args             = {keys: [@ssh.private_key_path],
                               paranoid: false}

      send_args             = ["start", @ssh.dns, @ssh.user_name, @ssh_args]
      @result               = Net::SSH.send_w_retries(*send_args) do |ssh|
                                ssh.run(command, except)
                              end
      return                  @result
    end

    def cp(loc_path, rem_path)
      @ssh                  = self
      @ssh_args             = {keys: [@ssh.private_key_path],
                               paranoid: false}
      send_args             = ["start",@ssh.dns,@ssh.user_name,@ssh_args]

      @result               = Net::SCP.send_w_retries(*send_args) do |scp|
                                scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
                                  Logger.info "#{name}: #{sent}/#{total}"
                                end
                              end
      return                  @result
    end
  end
end
