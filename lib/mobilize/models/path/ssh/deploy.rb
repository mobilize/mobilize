module Mobilize
  class Deploy
    include Mongoid::Document
    include Mongoid::Timestamps
    field :ssh_id, type: String
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :path_ids, type: Array #paths that need to be loaded before deploy to ssh
    field :replace_params, type: Hash
    field :_id, type: String, default:->{"#{ssh_id}:#{name}"}

    def ssh
      @deploy = self
      Ssh.find(@deploy.ssh_id)
    end

    def tmp_dir
      @deploy = self
      tmp_dir = "#{Mobilize.root}/tmp/mobilize/#{@deploy.ssh.user_ssh_name}/#{@deploy.name}"
      return tmp_dir
    end

    #replaces any replace_params in files with the replacement value given
    def replace
      @deploy = self
      @deploy.replace_params.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@deploy.tmp_dir} && (find ./ -type f | xargs sed -i 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
      end
    end

    #load paths into local directory
    def load
      @deploy = self
      @user = @ssh.user
      #clear out local
      FileUtils.rm_r(tmp_dir,force: true)
      FileUtils.mkdir_p(tmp_dir)
      #load each path into tmp_dir
      @deploy.path_ids.each do |path_id|
        path = Path.find(path_id)
        path.load(@user.id,tmp_dir)
        Logger.info("Loaded #{path.id} into #{tmp_dir}")
      end
      return tmp_dir
    end

    #transfer local directory to remote
    def transfer(command)
      @ssh = self
      @user = @ssh.user
      cmd = "rm -rf #{unique_name} && mkdir -p #{unique_name} && chown -R #{Ssh.node_owner(node)} #{unique_name}"
      response = @ssh.run(cmd)
      #clear out and regenerate remote folder
      puts response
      if tmp_dir
        Net::SCP.start(name,user,opts) do |scp|
          scp.upload!(from_path,to_path,:recursive=>true)
        end
        #make sure loc_dir is removed
        FileUtils.rm_r(tmp_dir,:force=>true)
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
      deploy_dir = "#{mobilize_dir}#{unique_name}/"
      deploy_cmd_path = "#{deploy_dir}cmd.sh"
      deploy_cmd = "sudo mkdir -p #{mobilize_dir} && " +
                   "sudo rm -rf  #{mobilize_dir}#{unique_name} && " +
                   "sudo mv #{unique_name} #{mobilize_dir} && " +
                   "sudo chown -R #{user_name} #{mobilize_dir} && " +
                   "sudo chmod -R 0700 #{user_name} #{mobilize_dir}"
      Ssh.fire!(node,deploy_cmd)
      #need to use bash or we get no tee
      full_cmd = "/bin/bash -l -c '(cd #{deploy_dir} && sh #{deploy_cmd_path} > >(tee stdout) 2> >(tee stderr >&2))'"
      #fire_cmd runs sh on cmd_path, optionally with sudo su
      fire_cmd = %{sudo su #{user_name} -c "#{full_cmd}"}
      @ssh.run(fire_cmd)
      return ""
    end

    def deploy(command,files)
      @ssh = self
      @ec2 = @ssh.ec2
      @user = @ssh.user
      tmp_dir = @ssh.populate_tmp_dir(deployment_name,files)
      return tmp_dir
    end
  end
end
