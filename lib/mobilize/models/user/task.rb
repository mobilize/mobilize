module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    belongs_to :job
    belongs_to :path
    field :input, type: String #used by run and write tasks to specify input
    field :gsubs, type: Hash #used by run and write tasks to gsub input
    field :call, type: String #method to call on path; read, run, write
    field :started_at, type: Time
    field :completed_at, type: Time
    field :failed_at, type: Time
    field :retried_at, type: Time
    field :status_at, type: Time
    field :status, type: String
    field :retries, type: String
    field :job_id, type: String #need for id
    field :path_id, type: String #need for id
    field :_id, type: String, default:->{"#{job_id}::#{path_id}##{call}"}

    @@config = Mobilize.config("task")

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

    #gsubs keys in files with the replacement value given
    def gsub!
      @task = self
      @task.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s).gsub("/","\\/") #also need to manually escape forward slash
        replace_cmd = "cd #{@task.cache} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@task.id}")
      end
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
      @task.path.sh("cat #{@task.cache}/#{stream.to_s}")[:stdout]
    end 
  end
end
