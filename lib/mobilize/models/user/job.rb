module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :command, type: String #command to be executed on the server
    field :gsubs, type: Hash #params to be replaced after read, before deploy
    field :_id, type: String, default:->{"#{self.user.id}/#{name}"}
    belongs_to :user
    belongs_to :cron
    embeds_many :tasks

    @@config = Mobilize.config.job

    def cache
      return "#{@@config.cache}/#{self.user.ssh_name}/#{self.name}"
    end

    def purge_cache
      #deletes its own cache and all task caches and removes self from db
      @job = self
      @job.tasks.each{|task| task.purge_cache}
      FileUtils.rm_r(@job.cache,:force=>true)
      Logger.info("Purged cache for #{@job}")
    end

    def compress_cache
      @job = self
      "cd #{@job.cache}/.. && tar -zcvf #{@job.name}.tar.gz #{@job.name}".popen4(true)
      Logger.info("Compressed worker to: #{@job.cache}.tar.gz")
    end

    def read_stdin
      @job = self
      File.open("#{@job.cache}/stdin","w") {|f| f.print(@job.command)}
      Logger.info("Read stdin into job cache for #{@job.id}")
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

    def Job.perform(job_id)
      @job = Job.find(job_id)
      @job.read_path_ids.each do |path_id|
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

    #read paths into worker directory
    def read
      @job = self
      @job.clear_cache
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
