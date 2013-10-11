module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
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
      @task                   = self
      @task.create_worker       task_id: @task.id
      Logger.info               "Created worker for #{@task.id}"
      @task.create_cache        task_id: @task.id
      Logger.info               "Created cache for #{@task.id}"
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
        @string1                = Regexp.escape(k.to_s) # escape any special characters
        @string2                = Regexp.escape(v.to_s).gsub("/","\\/") #also need to manually escape forward slash
        @replace_cmd            = "cd #{@task.worker.parent_dir} && " +
                                  "(find . -type f \\( ! -path '*/.*' \\) | " + #no hidden folders in relative path
                                  "xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        @replace_cmd.popen4
        Logger.info               "Replaced #{@string1} with #{@string2} in #{@task.worker.parent_dir}"
      end
    end

    def Task.perform(task_id)
      @task                      = Task.find(task_id)
      @path                      = @task.path
      @session                   = @path.class.session
      if                           @session
        @task.start
        begin
          @stage                 = @task.stage
          @path.send               @stage.call, @task
          @task.complete
        rescue                  => @exc
          if                       @task.retries < @@config.max_retries
            @task.retry
          else
            @task.fail
          end
        end
      else
        Logger.info                "No session available for #{@task.id}"
      end
    end

    def working?
      @task                  = self
      @workers               = Resque.workers
      @workers.index         {|worker|
        @payload             = worker.job['payload']
        if @payload
          @work_id           = @payload['args'].first
          @working           = true if @work_id == @task.id
        end
        @working
                             }
      @working
    end

    def queued?
      @task                  = self
      @queued_jobs           = ::Resque.peek(Mobilize.queue,0,0).to_a
      @queued_jobs.index     {|job|
        @work_id             = job['args'].first
        @queued              = true if @work_id == @task.id
                              }
      @queued
    end

    def retry
      @task                  = self
      @task.update_attributes  retries: @task.retries + 1
      Resque.enqueue_to        Mobilize.queue, Task, @task.id
    end

    def start
      @task                   = self
      @task.update_status       :started
    end

    def complete
      @task                   = self
      @task.update_status       :completed
    end

    def fail
      @task                   = self
      @task.update_status     = :failed
      @stage                  = @task.stage
      @stage.fail
    end

    #take a task worker
    #and send it over to cache
    #to ensure not too many connections are opened
    def deploy
      @task                       = self
      @cache                      = @task.cache
      @worker                     = @task.worker
      @cache.refresh
      @targz_rm_cmd               = "rm #{@worker.dir}.tar.gz"
      @targz_rm_cmd.popen4(false)
      Logger.info                   "Starting deploy for #{@task.id}"
      @task.gsub!
      @ssh                        = @task.user.ec2.ssh
      @worker.pack
      @ssh.cp                       "#{@worker.dir}.tar.gz", "#{@cache.dir}.tar.gz"
      @targz_rm_cmd.popen4(true)
      Logger.info                   "Deployed #{@task.id} to cache"
      @cache.unpack
      return true
    end

    #returns in, out, err, sig, log
    def streams
      @ssh = self.path
      @ssh.streams(self)
    end
  end
end
