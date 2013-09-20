module Mobilize
  class Transfer
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :name, type: String
    field :command, type: String #command to be executed on the server
    field :path_ids, type: Array #paths that need to be loaded before deploy to ec2
    field :gsubs, type: Hash #params to be replaced after load, before deploy
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
      return "#{@@config.workers.cache}/transfers/#{self.user.ssh_name}/#{self.name}"
    end

    def server_cache
      return "#{@@config.servers.cache}/transfers/#{self.user.ssh_name}/#{self.name}"
    end

    def purge!
      #deletes server and worker
      @transfer = self
      @transfer.purge_worker
      @transfer.purge_server
    end

    def purge_worker
      @transfer = self
      #remove worker dir
      FileUtils.rm_r(@transfer.worker_cache,:force=>true)
      Logger.info("Removed worker for #{@transfer.worker_cache}")
    end

    def purge_server
      @transfer = self
      @transfer.ssh("sudo rm -rf #{@transfer.server_cache}*")
      Logger.info("Removed #{@transfer.server_cache}*")
    end

    def create_server
      @transfer = self
      #clear out and regenerate server folder
      @transfer.ssh("mkdir -p #{@transfer.server_cache}")
      Logger.info("Created #{@transfer.server_cache}")
      return true
    end

    def clear_server
      @transfer = self
      @transfer.purge_server
      @transfer.create_server
      Logger.info("Cleared server: #{@transfer.server_cache}")
    end

    #clear out worker folder to load server contents
    def clear_worker
      @transfer = self
      @transfer.purge_worker
      FileUtils.mkdir_p(@transfer.worker_cache)
      Logger.info("Cleared worker at #{@transfer.worker_cache}")
      return true
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @transfer = self
      @transfer.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@transfer.worker_cache} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@transfer.id}")
      end
    end

    def load_paths(resque=false)
      @transfer = self
      @transfer.path_ids.each do |path_id|
        @path = Path.find(path_id)
        if resque
          Resque.enqueue!(@path.id,@transfer.id)
        else
          @path.load(@transfer.user_id,@transfer.worker_cache)
        end
      end
      return true
    end

    def load_stdin
      @transfer = self
      File.open("#{@transfer.worker_cache}/stdin","w") {|f| f.print(@transfer.command)}
      Logger.info("Wrote stdin to worker: #{@transfer.worker_cache}")
    end

    def compress_worker
      @transfer = self
      "cd #{@transfer.worker_cache}/.. && tar -zcvf #{@transfer.name}.tar.gz #{@transfer.name}".popen4(true)
      Logger.info("Compressed worker to: #{@transfer.worker_cache}.tar.gz")
    end

    #load paths into worker directory
    def load(resque=false)
      @transfer = self
      @transfer.clear_worker
      #load each path into worker
      @transfer.load_paths(resque)
      #write command to stdin folder in worker
      @transfer.load_stdin
      #replace any items that need it
      @transfer.gsub! unless @transfer.gsubs.nil? or @transfer.gsubs.empty?
      #compress worker dir
      @transfer.compress_worker
      #return path to worker dir file
      return "#{@transfer.worker_cache}.tar.gz"
    end

    def transfer
      Logger.info("Starting transfer for #{@transfer.id}")
      worker_path = "#{@transfer.worker_cache}.tar.gz"
      server_path = "#{@transfer.server_cache}.tar.gz"
      @transfer.scp(worker_path,server_path)
      Logger.info("Transfered #{@transfer.id} to server")
      server_cache_parent = @transfer.server_cache.split("/")[0..-2].join("/")
      @transfer.ssh("cd #{server_cache_parent} && tar -zxvf #{@transfer.name}.tar.gz")
      Logger.info("Unpacked server for #{@transfer.id}")
      return true
    end

    #deploy worker directory to server
    def deploy
      @transfer = self
      #clear out and regenerate server folder
      @transfer.clear_server
      #transfer worker directory to server
      @transfer.transfer
      @transfer.purge_worker
      exec_cmd = "(cd #{@transfer.server_cache} && sh stdin) > #{@transfer.server_cache}/stdout 2> #{@transfer.server_cache}/stderr"
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
      @transfer.ssh("cat #{@transfer.server_cache}/#{stream.to_s}")[:stdout]
    end
  end
end
