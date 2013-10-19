module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a job
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field :input,    type: String #used by write tasks to specify input
    field :subs,     type: Hash   #used by run tasks to sub input
    field :stage_id, type: String #need for id
    field :path_id,  type: String #need for id
    field :_id,      type: String, default:->{"#{stage_id}/#{path_id}"}
    belongs_to :stage
    belongs_to :path

    @@config = Mobilize.config("task")

    attr_accessor :session #used to hold onto session object for task

    def job
      self.stage.job
    end

    def user
      self.job.user
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      @task = self
      return nil unless @task.subs
      @task.subs.each do |k,v|
        @string1                = Regexp.escape(k.to_s) # escape any special characters
        @string2                = Regexp.escape(v.to_s).gsub("/","\\/") #also need to manually escape forward slash
        @replace_cmd            = "cd #{@task.dir} && " +
                                  "(find . -type f \\( ! -path '*/.*' \\) | " + #no hidden folders in relative path
                                  "xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        @replace_cmd.popen4
        Logger.write              "Replaced #{@string1} with #{@string2} in #{@task.dir}"
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
        Logger.write               "No session available for #{@task.id}"
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

    def dir
      @task                     = self
      @path                     = @task.path
      if @path.class == Script  #scripts use the alphanunderscrore name for the directory
        @dir                    = "#{Job.dir}/#{@task.stage.id}/script/#{@path.name}"
      else
        @dir                    = "#{Job.dir}/#{@task.id}"
      end
      return                    @dir
    end

    def path_dir
      @task                     = self
      @path_dir                 = File.dirname @task.dir
      return                      @path_dir
    end

    def refresh_dir
      @task                     = self
      FileUtils.rm_r              @task.dir, force: true
      FileUtils.mkdir_p           @task.dir
      Logger.write                "Refreshed task dir " + @task.dir
    end

    def purge_dir
      @task                     = self
      FileUtils.mkdir_p           @task.dir
      FileUtils.rm_r              @task.dir, force: true
      Logger.write                "Purged task dir "    + @task.dir
    end

    def create_dir
      @task                     = self
      FileUtils.mkdir_p           @task.dir
      Logger.write                "Created task dir "   + @task.dir
    end
  end
end
