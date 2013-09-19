module Mobilize
  class Job
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

    #tmp folder for caching jobs
    def tmp
      return "#{Mobilize.tmp}/jobs/#{self.user.ssh_name}/#{self.name}"
    end

    def purge!
      #deletes remote and local
      @job = self
      @job.purge_local
      @job.purge_remote
    end

    def purge_local
      @job = self
      #remove local dir
      FileUtils.rm_r(@job.tmp,:force=>true)
      Logger.info("Removed local for #{@job.tmp}")
    end

    def purge_remote
      @job = self
      @job.ssh("sudo rm -rf #{@job.tmp}*")
      Logger.info("Removed #{@job.tmp}")
    end

    def create_home
      @job = self
      #clear out and regenerate remote folder
      @job.ssh("sudo mkdir -p #{@job.home}")
      Logger.info("Created #{@job.home}")
      @job.ssh("sudo chown #{Mobilize.ec2_root_user} #{@job.user.home}")
      Logger.info("Chowned #{@job.user.home} to #{Mobilize.ec2_root_user}")
      @job.ssh("sudo chown #{Mobilize.ec2_root_user} #{@job.home}")
      Logger.info("Chowned #{@job.home} to #{Mobilize.ec2_root_user}")
      return true
    end

    def clear_remote
      @job = self
      @job.purge_remote
      @job.create_home
      Logger.info("Cleared remote: #{home}")
    end

    #clear out local folder to load remote contents
    def clear_local
      @job = self
      @job.purge_local
      FileUtils.mkdir_p(@job.tmp)
      Logger.info("Cleared local at #{@job.tmp}")
      return true
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @job = self
      @job.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@job.tmp} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@job.id}")
      end
    end

    def load_paths(resque=false)
      @job = self
      @job.path_ids.each do |path_id|
        @path = Path.find(path_id)
        if resque
          Resque.enqueue!(@path.id,@job.id)
        else
          @path.load(@job.user_id,@job.tmp)
        end
      end
      return true
    end

    def load_stdin
      @job = self
      File.open("#{@job.tmp}/stdin","w") {|f| f.print(@job.command)}
      Logger.info("Wrote stdin to local: #{@job.tmp}")
    end

    def compress_local
      @job = self
      "cd #{@job.tmp}/.. && tar -zcvf #{@job.name}.tar.gz #{@job.name}".popen4(true)
      Logger.info("Compressed local to: #{@job.tmp}.tar.gz")
    end

    #load paths into local directory
    def load(resque=false)
      @job = self
      @job.clear_local
      #load each path into local
      @job.load_paths(resque)
      #write command to stdin folder in local
      @job.load_stdin
      #replace any items that need it
      @job.gsub! unless @job.gsubs.nil? or @job.gsubs.empty?
      #compress local dir
      @job.compress_local
      #return path to local dir file
      return "#{@job.tmp}.tar.gz"
    end

    def transfer
      Logger.info("Starting transfer for #{@job.id}")
      rem_path = "#{@job.home}/#{@job.name}.tar.gz"
      loc_path = "#{@job.tmp}.tar.gz"
      @job.scp(loc_path,rem_path)
      Logger.info("Transfered #{@job.id} to remote")
      @job.ssh("cd #{@job.home} && tar -zxvf #{@job.name}.tar.gz")
      Logger.info("Unpacked remote for #{@job.id}")
      return true
    end

    #deploy local directory to remote
    def deploy
      @job = self
      #clear out and regenerate remote folder
      @job.clear_remote
      #transfer local directory to remote
      @job.transfer
      @job.purge_local
      exec_cmd = "(cd #{@job.tmp} && sh stdin) > #{@job.tmp}/stdout 2> #{@job.tmp}/stderr"
      return exec_cmd
    end

    def execute
      @job = self
      @job.load
      exec_cmd = @job.deploy
      begin
        @job.ssh(exec_cmd)
        Logger.info("Completed job for #{@job.id}")
      rescue
        Logger.error("Failed job #{@job.id} with #{@job.stderr}")
      end
      return @job.stdout
    end

    #defines 3 methods for retrieving each of the streams
    #as recorded in their files
    #def_each is included in extensions
    def_each :stdin, :stdout, :stderr do |stream|
      @job = self
      Logger.info("retrieving #{stream.to_s} for #{@job.id}")
      @job.ssh("cat #{@job.tmp}/#{stream.to_s}")[:stdout]
    end
  end
end
