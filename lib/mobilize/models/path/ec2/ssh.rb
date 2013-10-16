module Mobilize
  class Ssh
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Recipe
    field      :user_name,        type: String, default:->{Mobilize.config.ssh.user_name}
    field      :home_dir,         type: String, default:->{"/home/#{user_name}"}
    belongs_to :ec2

    def Ssh.private_key_path;     "#{Mobilize.home_dir}/keys/ec2.ssh"; end #created during configuration

    def shell_cmd
      @ssh                      = self
      @ssh_cmd                  = "ssh -i #{Ssh.private_key_path} #{@ssh.user_name}@#{@ssh.dns}"
      Logger.info                 "Log in with: #{@ssh_cmd}"
      return                      true
    end

    def sh(command,  except     = true)
      @ssh                      = self
      @ssh_args                 = {keys: [Ssh.private_key_path],
                                   paranoid: false}

      send_args                 = ["start", @ssh.dns, @ssh.user_name, @ssh_args]
      @result                   = Net::SSH.send_w_retries(*send_args) do |ssh|
                                    ssh.run(command, except)
                                  end
      return                      @result
    end

    def cp(loc_path, rem_path)
      @ssh                      = self
      @ssh_args                 = {keys: [@ssh.private_key_path],
                                   paranoid: false}
      send_args                 = ["start",@ssh.dns,@ssh.user_name,@ssh_args]

      @result                   = Net::SCP.send_w_retries(*send_args) do |scp|
                                    scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
                                      Logger.info "#{name}: #{sent}/#{total}"
                                    end
                                  end
      return                      @result
    end

    def write(string, rem_path)
      @ssh                      = self
      @string, @rem_path        = string, rem_path
      @file                     = Tempfile.new 'ssh_write'
      begin
        @file.write               @string
        @file.close
        @ssh.sh                   "mkdir -p " + File.dirname(@rem_path)
        @ssh.cp                   @file.path, @rem_path
      ensure
        @file.close
        @file.unlink
      end
      Logger.info                 "Wrote string #{@string.ellipsize(10)} to #{@ssh.id}:#{@rem_path}"
    end
  end
end
