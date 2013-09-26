module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    belongs_to :job
    belongs_to :path
    field :stdin, type: String
    field :gsubs, type: Hash
    field :call, type: String #method to call on path
    field :started_at, type: Time
    field :completed_at, type: Time
    field :failed_at, type: Time
    field :retried_at, type: Time
    field :status_at, type: Time
    field :status, type: String
    field :retries, type: String
    field :_id, type: String, default:->{"#{job_id}::#{path_id}##{call}"}

    @@config = Mobilize.config.task

    attr_accessor :session #used to hold onto session object for task

    def user
      self.job.user
    end
    
    def cache
      self.path.cache(self)
    end

    def purge_cache
      self.path.purge_cache(self)
    end

    def get_status
      #try to get status from redis first
      #then from job
    end

    def set_status(message)
      #set status in redis first if possible
      #then in DB
    end

    def Task.perform(task_id)
      @task    = Task.find(task_id)
      @session = @task.path_model.session
      if @session
        @task.set_status("started")
        begin
          @path.send(@task.name,@task)
        rescue => @exc
          @task.set_status("failed")
          message = "Failed task #{@task.id} with #{@exc.to_s}"
          if @task.retries < @@config.total_retries
            Logger.info(message)
          else
            Logger.error(message)
          end
        end
        @task.set_status("complete")
        Logger.info("Completed task #{@task.id}")
      else
        @task.requeue("No session available")
      end
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

    #for SSH tasks only
    #defines 3 methods for retrieving each of the streams
    #as recorded in their files
    #def_each is included in extensions
    def_each :stdin, :stdout, :stderr do |stream|
      @task = self
      Logger.error("Not an SSH task") unless @task.path.class == Mobilize::Ssh
      Logger.info("retrieving #{stream.to_s} for #{@task.id}")
      @task.sh("cat #{@task.path.cache}/#{stream.to_s}")[:stdout]
    end 
  end
end
