module Mobilize
  class Transfer
    include Mongoid::Document
    include Mongoid::Timestamps
    field :ssh_id, type: String
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :command, type: String #command to be executed on the remote
    field :path_ids, type: Array #paths that need to be loaded before transfer to ssh
    field :replace_params, type: Hash
    field :_id, type: String, default:->{"#{ssh_id}:#{name}"}

    def ssh
      @transfer = self
      Ssh.find(@transfer.ssh_id)
    end

    def loc_dir
      @transfer = self
      return "#{Mobilize.root}/tmp/mobilize/#{@transfer.ssh.user_ssh_name}/#{@transfer.name}"
    end

    def rem_dir
      @transfer = self
      @ssh = @transfer.ssh
      return "/home/#{@ssh.ssh_user_name}/mobilize/transfers/#{}"
    end

    #replaces any replace_params in files with the replacement value given
    def replace
      @transfer = self
      @transfer.replace_params.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@transfer.loc_dir} && (find ./ -type f | xargs sed -i 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
      end
    end

    #load paths into local directory
    def load
      @transfer = self
      @user = @ssh.user
      #clear out local
      FileUtils.rm_r(@transfer.loc_dir,force: true)
      FileUtils.mkdir_p(@transfer.loc_dir)
      #load each path into loc_dir
      @transfer.path_ids.each do |path_id|
        @path = Path.find(path_id)
        @path.load(@user.id,@transfer.loc_dir)
        Logger.info("Loaded #{@path.id} into #{@transfer.loc_dir}")
      end
      return @transfer.loc_dir
    end

    #deploy local directory to remote
    def deploy
      @ssh = self
      @user = @ssh.user
      @session = @ssh.login
      @session.run
      cmd = "rm -rf #{unique_name} && mkdir -p #{unique_name} && chown -R #{Ssh.node_owner(node)} #{unique_name}"
      response = @ssh.run(cmd)
      #clear out and regenerate remote folder
      puts response
      if loc_dir
        Net::SCP.start(name,user,opts) do |scp|
          scp.upload!(from_path,to_path,:recursive=>true)
        end
        #make sure loc_dir is removed
        FileUtils.rm_r(loc_dir,:force=>true)
      end
      from_path = Ssh.tmp_file(fdata,binary)
      Ssh.scp(node,from_path,to_path)
    end

    def execute
      #create cmd_file in unique_name
      #cmd_path = "#{unique_name}/cmd.sh"
      #move folder to user's home, change ownership
      user_dir = "/home/#{user_name}/"
      mobilize_dir = "#{user_dir}mobilize/"
      transfer_dir = "#{mobilize_dir}#{unique_name}/"
      transfer_cmd_path = "#{transfer_dir}cmd.sh"
      transfer_cmd = "sudo mkdir -p #{mobilize_dir} && " +
                   "sudo rm -rf  #{mobilize_dir}#{unique_name} && " +
                   "sudo mv #{unique_name} #{mobilize_dir} && " +
                   "sudo chown -R #{user_name} #{mobilize_dir} && " +
                   "sudo chmod -R 0700 #{user_name} #{mobilize_dir}"
      Ssh.fire!(node,transfer_cmd)
      #need to use bash or we get no tee
      full_cmd = "/bin/bash -l -c '(cd #{transfer_dir} && sh #{transfer_cmd_path} > >(tee stdout) 2> >(tee stderr >&2))'"
      #fire_cmd runs sh on cmd_path, optionally with sudo su
      fire_cmd = %{sudo su #{user_name} -c "#{full_cmd}"}
      @ssh.run(fire_cmd)
      return ""
    end

    def transfer(command)
      @ssh = self
      @ec2 = @ssh.ec2
      @user = @ssh.user
      loc_dir = @ssh.populate_loc_dir(transferment_name,files)
      return loc_dir
    end
  end
end
