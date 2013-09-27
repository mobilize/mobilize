module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String, default:->{Time.now.utc.strftime("%Y%m%d%H%M%S")}
    field :user_id, type: String #need for id
    field :_id, type: String, default:->{"#{user_id}/#{name}"}
    belongs_to :user
    has_many :tasks

    @@config = Mobilize.config("job")

    #job overrides cache methods to act on root folder
    def cache
      return File.expand_path("#{@@config.cache}/#{self.user.ssh_name}/#{self.name}"
    end

    def clear_cache
      @job = self
      @job.purge_cache
      @job.create_cache
      Logger.info("Cleared cache for #{@job.id}")
    end

    def create_cache
      @job = self
      FileUtils.mkdir_p(@job.cache)
      Logger.info("Created cache for #{@job.id}")
    end

    def purge_cache
      #deletes its own cache and all task caches and removes self from db
      @job = self
      @job.tasks.each{|task| task.purge_cache}
      FileUtils.rm_r(@job.cache,:force=>true)
      Logger.info("Purged cache for #{@job.id}")
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
  end
end
