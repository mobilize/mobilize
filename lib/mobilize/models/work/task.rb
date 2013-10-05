module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Status
    field :input,    type: String #used by run and write tasks to specify input
    field :subs,     type: Hash   #used by run and write tasks to gsub input
    field :stage_id, type: String #need for id
    field :path_id,  type: String #need for id
    field :_id,      type: String, default:->{"#{stage_id}#{path_id}"}
    belongs_to :job
    belongs_to :path
    has_one :cache
    has_one :worker

    @@config = Mobilize.config("task")

    attr_accessor :session #used to hold onto session object for task

    #assign a cache and worker to task on creation
    after_create :find_or_create_worker_and_cache
    def find_or_create_worker_and_cache
      @task       = self
      @task       .create_worker(task_id: @task.id)
      Logger.info "Created worker for #{@task.id}"
      @task       .create_cache(task_id: @task.id)
      Logger.info "Created cache for #{@task.id}"
    end

    def user
      self.job.user
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
      return nil unless @task.subs
      @task.subs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s).gsub("/","\\/") #also need to manually escape forward slash
        replace_cmd = "cd #{@task.worker.parent_dir} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} in #{@task.worker.parent_dir}")
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

    #take a task worker
    #and send it over to cache
    #to ensure not too many connections are opened
    def deploy
      @task = self
      @cache = @task.cache
      @worker = @task.worker
      @cache.refresh
      "rm #{@worker.dir}.tar.gz".popen4(false)
      Logger.info("Starting deploy for #{@task.id}")
      @task.gsub!
      @ssh = @task.user.ec2.ssh
      @worker.pack
      @ssh.cp("#{@worker.dir}.tar.gz","#{@cache.dir}.tar.gz")
      "rm #{@worker.dir}.tar.gz".popen4(true)
      Logger.info("Deployed #{@task.id} to cache")
      @cache.unpack
      return true
    end

    #returns in, out, err, sig, log
    def streams
      @ssh = self.path
      @ssh .streams(self)
    end

  end
end
