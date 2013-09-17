module Mobilize
  class Transfer
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :command, type: String #command to be executed on the remote
    field :path_ids, type: Array #paths that need to be loaded before deploy to ec2
    field :gsubs, type: Hash #params to be replaced after load, before deploy
    field :_id, type: String, default:->{"#{user_id}:#{name}"}

    def user
      User.find(self.user_id)
    end

    def ec2
      self.user.ec2
    end

    def ssh
      self.user.ec2.ssh
    end

    def scp(loc_path,rem_path)
      self.user.ec2.scp(loc_path,rem_path)
    end

    def home_dir
      self.user.home_dir
    end

    def loc_dir
      return "#{Mobilize.root}/tmp/#{self.home_dir}/#{self.name}"
    end

    def rem_dir
      return "#{self.home_dir}/#{self.name}"
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @transfer = self
      @transfer.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@transfer.loc_dir} && (find . -type f | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@transfer.id}")
      end
    end

    #load paths into local directory
    def load
      @transfer = self
      #clear out local
      FileUtils.rm_r(@transfer.loc_dir,force: true)
      FileUtils.mkdir_p(@transfer.loc_dir)
      #load each path into loc_dir
      @transfer.path_ids.each do |path_id|
        @path = Path.find(path_id)
        @path.load(@transfer.user_id,@transfer.loc_dir)
        Logger.info("Loaded #{@path.id} into #{@transfer.loc_dir}")
      end
      #write command to stdin folder in local
      File.open("#{@transfer.loc_dir}/stdin","w") {|f| f.print(@transfer.command)}
      Logger.info("Wrote stdin to local: #{@transfer.loc_dir}")
      #replace any items that need it
      @transfer.gsub! unless @transfer.gsubs.nil? or @transfer.gsubs.empty?
      #compress local dir
      "cd #{@transfer.loc_dir}/.. && tar -zcvf #{@transfer.name}.tar.gz #{@transfer.name}".popen4(true)
      Logger.info("Compressed local to: #{@transfer.loc_dir}.tar.gz")
      #return path to local dir file
      return "#{@transfer.loc_dir}.tar.gz"
    end

    def refresh_rem_dir
      @transfer = self
      @ssh = @transfer.ssh
      rem_dir = @transfer.rem_dir
      home_dir = @transfer.home_dir
      #clear out and regenerate remote folder
      @ssh.run("sudo rm -rf #{rem_dir}*")
      Logger.info("Removed #{rem_dir}")
      @ssh.run("sudo mkdir -p #{home_dir}")
      Logger.info("Mkdir'ed #{home_dir}")
      @ssh.run("sudo chown #{ENV['MOB_EC2_ROOT_USER']} #{home_dir}")
      Logger.info("Chowned #{home_dir} to #{ENV['MOB_EC2_ROOT_USER']}")
      Logger.info("Refreshed remote: #{home_dir}")
    end

    #deploy local directory to remote
    def deploy
      @transfer = self
      #clear out and regenerate remote folder
      @transfer.refresh_rem_dir
      #transfer local directory to remote
      Logger.info("Starting upload to remote for #{@transfer.id}")
      rem_path = "#{@transfer.user.home_dir}/#{@transfer.name}.tar.gz"
      loc_path = "#{@transfer.loc_dir}.tar.gz"
      @transfer.scp(loc_path,rem_path)
      Logger.info("uploaded local to remote for #{@transfer.id}")
      @transfer.ssh.run("cd #{@transfer.home_dir} && tar -zxvf #{@transfer.name}.tar.gz")
      Logger.info("Unpacked remote for #{@transfer.id}")
      #remove local dir
      FileUtils.rm_r(@transfer.loc_dir,:force=>true)
      Logger.info("Removed local for #{@transfer.loc_dir}")
      exec_cmd = "(cd #{@transfer.rem_dir} && sh stdin) > #{@transfer.rem_dir}/stdout 2> #{@transfer.rem_dir}/stderr"
      return exec_cmd
    end

    def execute
      @transfer = self
      @transfer.load
      exec_cmd = @transfer.deploy
      begin
        @transfer.ssh.run(exec_cmd)
        Logger.info("Completed transfer for #{@transfer.id}")
      rescue
        Logger.error("Failed transfer #{@transfer.id} with #{@transfer.stderr}")
      end
      return @transfer.stdout
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
