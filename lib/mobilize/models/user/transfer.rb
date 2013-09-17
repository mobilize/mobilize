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

    def ssh(command,except=true)
      self.user.ec2.ssh(command,except)
    end

    def scp(loc_path,rem_path)
      self.user.ec2.scp(loc_path,rem_path)
    end

    def home
      "#{self.user.home}/transfers"
    end

    def local
      return "#{Mobilize.root}/tmp#{self.home}/#{self.name}"
    end

    def remote
      return "#{self.home}/#{self.name}"
    end

    def purge!
      #deletes remote and local
      @transfer = self
      @transfer.purge_local
      @transfer.purge_remote
    end

    def purge_remote
      @transfer = self
      @transfer.ssh("sudo rm -rf #{@transfer.remote}*")
      Logger.info("Removed #{@transfer.remote}")
    end

    def create_home
      @transfer = self
      #clear out and regenerate remote folder
      @transfer.ssh("sudo mkdir -p #{@transfer.home}")
      Logger.info("Created #{@transfer.home}")
      @transfer.ssh("sudo chown #{ENV['MOB_EC2_ROOT_USER']} #{@transfer.user.home}")
      Logger.info("Chowned #{@transfer.user.home} to #{ENV['MOB_EC2_ROOT_USER']}")
      @transfer.ssh("sudo chown #{ENV['MOB_EC2_ROOT_USER']} #{@transfer.home}")
      Logger.info("Chowned #{@transfer.home} to #{ENV['MOB_EC2_ROOT_USER']}")
      return true
    end

    def purge_local
      @transfer = self
      #remove local dir
      FileUtils.rm_r(@transfer.local,:force=>true)
      Logger.info("Removed local for #{@transfer.local}")
    end

    def clear_remote
      @transfer = self
      @transfer.purge_remote
      @transfer.create_home
      Logger.info("Cleared remote: #{home}")
    end

    #clear out local folder to load remote contents
    def clear_local
      @transfer = self
      @transfer.purge_local
      FileUtils.mkdir_p(@transfer.local)
      Logger.info("Cleared local at #{@transfer.local}")
      return true
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @transfer = self
      @transfer.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@transfer.local} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@transfer.id}")
      end
    end

    def load_paths
      @transfer = self
      @transfer.path_ids.each do |path_id|
        @path = Path.find(path_id)
        @path.load(@transfer.user_id,@transfer.local)
        Logger.info("Loaded #{@path.id} into #{@transfer.local}")
      end
      return true
    end

    def load_stdin
      @transfer = self
      File.open("#{@transfer.local}/stdin","w") {|f| f.print(@transfer.command)}
      Logger.info("Wrote stdin to local: #{@transfer.local}")
    end

    def compress_local
      @transfer = self
      "cd #{@transfer.local}/.. && tar -zcvf #{@transfer.name}.tar.gz #{@transfer.name}".popen4(true)
      Logger.info("Compressed local to: #{@transfer.local}.tar.gz")
    end

    #load paths into local directory
    def load
      @transfer = self
      @transfer.clear_local
      #load each path into local
      @transfer.load_paths
      #write command to stdin folder in local
      @transfer.load_stdin
      #replace any items that need it
      @transfer.gsub! unless @transfer.gsubs.nil? or @transfer.gsubs.empty?
      #compress local dir
      @transfer.compress_local
      #return path to local dir file
      return "#{@transfer.local}.tar.gz"
    end

    def local_to_remote
      Logger.info("Starting upload to remote for #{@transfer.id}")
      rem_path = "#{@transfer.home}/#{@transfer.name}.tar.gz"
      loc_path = "#{@transfer.local}.tar.gz"
      @transfer.scp(loc_path,rem_path)
      Logger.info("Uploaded local to remote for #{@transfer.id}")
      @transfer.ssh("cd #{@transfer.home} && tar -zxvf #{@transfer.name}.tar.gz")
      Logger.info("Unpacked remote for #{@transfer.id}")
      return true
    end

    #deploy local directory to remote
    def deploy
      @transfer = self
      #clear out and regenerate remote folder
      @transfer.clear_remote
      #transfer local directory to remote
      @transfer.local_to_remote
      @transfer.purge_local
      exec_cmd = "(cd #{@transfer.remote} && sh stdin) > #{@transfer.remote}/stdout 2> #{@transfer.remote}/stderr"
      return exec_cmd
    end

    def execute
      @transfer = self
      @transfer.load
      exec_cmd = @transfer.deploy
      begin
        @transfer.ssh(exec_cmd)
        Logger.info("Completed transfer for #{@transfer.id}")
      rescue
        Logger.error("Failed transfer #{@transfer.id} with #{@transfer.stderr}")
      end
      return @transfer.stdout
    end

    #defines 3 methods for retrieving each of the streams
    #as recorded in their files
    #def_each is included in extensions
    def_each :stdin, :stdout, :stderr do |stream|
      @transfer = self
      Logger.info("retrieving #{stream.to_s} for #{@transfer.id}")
      @transfer.ssh("cat #{@transfer.remote}/#{stream.to_s}")[:stdout]
    end
  end
end
