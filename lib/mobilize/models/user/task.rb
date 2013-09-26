module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    embedded_in :job
    belongs_to :path
    field :call, type: String #method to call on path
    field :started_at, type: Time
    field :completed_at, type: Time
    field :failed_at, type: Time
    field :status_at, type: Time
    field :_id, type: String, default:->{"#{self.job.id}::#{self.path.id}##{call}"}

    @@config = Mobilize.config.task

    def initialize(job_id,path_id,name,status)
      path_kind           = path_id.split("::").first
      @path_model         = "Mobilize::#{path_kind.capitalize}".constantize
      @path               = @path_model.find(path_id)
      @job                = Job.find(job_id)
      @name               = name
      @status_message     = status.split("::").first
      @status_time        = status.split("::").last
    end

    def cache
      return self.path.cache(self)
    end

    def purge!
      #deletes its own cache and all task caches
      @job = self
      FileUtils.rm_r(@job.cache,:force=>true)
      Logger.info("Removed cache for #{@job}")
      @job.tasks.each{|task| task.purge!}
    end

    def status
      #try to get status from redis first
      #then try to get completeness from job
    end

    def Task.perform(job_id,path_id,name,status="queued::#{Time.now.utc}")
      @task = Task.new(job_id,path_id,name,status)
      @session = @task.path_model.session
      if @session
        @task.set_status("working")
        @path.send(@task.name,@task)
        @task.set_status("complete")
      else
        @task.requeue("No session available")
      end
    end

    def waiting?

    end

    def requeue(message)
      @task = self
      #update status if the message has changed or if 
      #it has been longer than the log frequency
      if message != @task.status_message or 
        Time.now.utc > (@task.status_time + @@config.log_frequency)
        Logger.info(@task.status_message)
      end
      Resque.enqueue(Task,@task.job.id,@task.path.id,@task.method,@task.status)
    end
  end
end
