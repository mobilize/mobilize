module Mobilize
  class Transfer
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :command, type: String #command to be executed on the remote
    field :path_ids, type: Array #paths that need to be loaded before deploy to ec2
    field :replace_params, type: Hash #params to be replaced after load, before deploy
    field :_id, type: String, default:->{"#{user_id}:#{name}"}

    def user
      @transfer = self
      Ssh.find(@transfer.user_id)
    end

    def loc_dir
      @transfer = self
      return "#{Mobilize.root}/tmp/mobilize/#{@transfer.user.home_dir}/#{@transfer.name}"
    end

    def rem_dir
      @transfer = self
      return "#{@transfer.user.home_dir}/#{@transfer.name}"
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
      #write command to stdin folder in local
      File.open("#{@transfer.loc_dir}/stdin","w") {|f| f.print(@transfer.command)}
      Logger.info("Wrote stdin to local: #{@transfer.loc_dir}")
      return @transfer.loc_dir
    end

    #deploy local directory to remote
    def deploy
      @transfer = self
      @ec2 = @transfer.ec2
      @ssh = @ec2.ssh
      #clear out and regenerate remote folder
      ["sudo rm -rf #{@transfer.rem_dir}",
       "mkdir -p #{@transfer.rem_dir}"
      ].each{|cmd| @ssh.run(cmd)}
      Logger.info("Cleared out remote: #{@transfer.rem_dir}")

      #transfer local directory to remote
      Net::SCP.start(@ec2.dns,ENV['MOB_EC2_ROOT_USER'],:keys=>ENV['MOB_EC2_PRIV_KEY_PATH']) do |scp|
        scp.upload!(@transfer.loc_dir,@transfer.rem_dir,:recursive=>true)
      end
      Logger.info("uploaded local to remote for #{@transfer.id}")

      #remove local dir
      FileUtils.rm_r(@transfer.loc_dir,:force=>true)
      Logger.info("Removed local for #{@transfer.loc_dir}")

      #return full exec command with tee
      start_cmd = "/bin/bash -l -c '(cd #{@transfer.rem_dir} && sh #{@transfer.rem_path} > >(tee stdout) 2> >(tee stderr >&2))'"

      return start_cmd
    end

    def execute
      @transfer = self
      @transfer.load
      start_cmd = @transfer.deploy
      result = @transfer.ec2.run(start_cmd)
      return result[:stdout]
    end

    def stdin
      @transfer = self
      Logger.info("retrieving stdin for #{@transfer.id}")
      @transfer.ssh.run("cat #{@transfer.rem_dir}/stdin")[:stdout]
    end

    def stdout
      @transfer = self
      Logger.info("retrieving stdout for #{@transfer.id}")
      @transfer.ssh.run("cat #{@transfer.rem_dir}/stdout")[:stdout]
    end

    def stderr
      @transfer = self
      Logger.info("retrieving stderr for #{@transfer.id}")
      @transfer.ssh.run("cat #{@transfer.rem_dir}/stderr")[:stdout]
    end
  end
end
