module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :job_id, type: String
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :command, type: String #command to be executed on the server
    field :input_path_ids, type: Array #paths that need to be read for deploy to ec2
    field :output_path_ids, type: Array #paths that will be written after deploy to ec2
    field :gsubs, type: Hash #params to be replaced after read, before deploy
    field :_id, type: String, default:->{"#{user_id}:#{name}"}

    @@config = Mobilize.config

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

    def worker_cache
      return "#{@@config.workers.cache}/jobs/#{self.user.ssh_name}/#{self.name}"
    end

    def server_cache
      return "#{@@config.servers.cache}/jobs/#{self.user.ssh_name}/#{self.name}"
    end

    def purge!
      #deletes server and worker
      @job = self
      @job.purge_worker
      @job.purge_server
    end

    def purge_worker
      @job = self
      #remove worker dir
      FileUtils.rm_r(@job.worker_cache,:force=>true)
      Logger.info("Removed worker for #{@job.worker_cache}")
    end

    def purge_server
      @job = self
      @job.ssh("sudo rm -rf #{@job.server_cache}*")
      Logger.info("Removed #{@job.server_cache}*")
    end

    def create_server
      @job = self
      #clear out and regenerate server folder
      @job.ssh("mkdir -p #{@job.server_cache}")
      Logger.info("Created #{@job.server_cache}")
      return true
    end

    def clear_server
      @job = self
      @job.purge_server
      @job.create_server
      Logger.info("Cleared server: #{@job.server_cache}")
    end

    #clear out worker folder to commit server contents
    def clear_worker
      @job = self
      @job.purge_worker
      FileUtils.mkdir_p(@job.worker_cache)
      Logger.info("Cleared worker at #{@job.worker_cache}")
      return true
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @job = self
      @job.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@job.worker_cache} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@job.id}")
      end
    end

    def read_paths(resque=false)
      @job = self
      @job.input_path_ids.each do |path_id|
        @path = Path.find(path_id)
        if resque
          Resque.enqueue!(@path.id,@job.id)
        else
          @path_session = @path.class.login
          @path.read(@path_session,@job.user_id,@job.worker_cache)
        end
      end
      return true
    end

    def read_stdin
      @job = self
      File.open("#{@job.worker_cache}/stdin","w") {|f| f.print(@job.command)}
      Logger.info("Read stdin into worker: #{@job.worker_cache}")
    end

    def compress_worker
      @job = self
      "cd #{@job.worker_cache}/.. && tar -zcvf #{@job.name}.tar.gz #{@job.name}".popen4(true)
      Logger.info("Compressed worker to: #{@job.worker_cache}.tar.gz")
    end

    #read paths into worker directory
    def read(resque=false)
      @job = self
      @job.clear_worker
      #read each path into worker
      @job.read_paths(resque)
      #write command to stdin folder in worker
      @job.read_stdin
      #replace any items that need it
      @job.gsub! unless @job.gsubs.nil? or @job.gsubs.empty?
      #compress worker dir
      @job.compress_worker
      #return path to worker dir file
      return "#{@job.worker_cache}.tar.gz"
    end

    def commit
      Logger.info("Starting job for #{@job.id}")
      worker_path = "#{@job.worker_cache}.tar.gz"
      server_path = "#{@job.server_cache}.tar.gz"
      @job.scp(worker_path,server_path)
      Logger.info("SCP'ed #{@job.id} to server")
      server_cache_parent = @job.server_cache.split("/")[0..-2].join("/")
      @job.ssh("cd #{server_cache_parent} && tar -zxvf #{@job.name}.tar.gz")
      Logger.info("Unpacked server for #{@job.id}")
      return true
    end

    #deploy worker directory to server
    def deploy
      @job = self
      #clear out and regenerate server folder
      @job.clear_server
      #job worker directory to server
      @job.commit
      @job.purge_worker
      return true
    end

    def execute
      @job = self
      @job.read
      @job.deploy
      begin
        exec_cmd = "(cd #{@job.server_cache} && sh stdin) > " +
                   "#{@job.server_cache}/stdout 2> " +
                   "#{@job.server_cache}/stderr"
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
      @job.ssh("cat #{@job.server_cache}/#{stream.to_s}")[:stdout]
    end
  end
end
