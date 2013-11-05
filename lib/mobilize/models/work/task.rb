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

    after_initialize :set_self
    def set_self; @task = self;end

    def job
      self.stage.job
    end

    def user
      self.job.user
    end

    #gsubs keys in files with the replacement value given
    def gsub!
      return nil unless @task.subs
      @task.subs.each         do |_search, _replace|
        _string1                = Regexp.escape  _search.to_s # escape any special characters
        _string2                = Regexp.escape( _replace.to_s ).gsub "/", "\\/" #also need to manually escape forward slash
        _replace_cmd            = "cd #{ @task.dir } && " +
                                  "(find . -type f \\( ! -path '*/.*' \\) | " + #no hidden folders in relative path
                                  "xargs sed -ie 's/#{ _string1 }/#{ _string2 }/g')"
        _replace_cmd.popen4
        Log.write                 "Replaced #{ _string1 } with #{ _string2 } in #{ @task.dir }"
      end
    end

    def Task.perform( _task_id )
      @task                      = Task.find _task_id
      _path                      = @task.path
      _session                   = _path.class.session
      if                           _session
        @task.start
        begin
          _stage                 = @task.stage
          _path.send               _stage.call, @task
          @task.complete
        rescue                  => _exc
          if                       @task.retries < @@config.max_retries
            Log.write              "Failed #{ @task.id } with #{ _exc.to_s }", "ERROR"
            @task.retry
          else
            @task.fail
          end
        end
      else
        Log.write                  "No session available for #{ @task.id }"
      end
    end

    def working?
      _workers               = Resque.workers
      _workers.index        { |worker|
        _payload             = worker.job[ 'payload' ]
        if _payload
          _work_id           = _payload[ 'args' ].first
          _working           = true if _work_id == @task.id
        end
        _working
                             }
      _working
    end

    def queued?
      _queued_jobs           = ::Resque.peek( Mobilize.queue, 0, 0 ).to_a
      _queued_jobs.index    { |job|
        _work_id             = job[ 'args' ].first
        @queued              = true if _work_id == @task.id
                              }
      @queued
    end

    def retry
      @task.update_attributes  retries: @task.retries + 1
      Resque.enqueue_to        Mobilize.queue, Task, @task.id
    end

    def start
      @task.update_status       :started
    end

    def complete
      @task.update_status       :completed
    end

    def fail
      @task.update_status     = :failed
      _stage                  = @task.stage
      _stage.fail
    end

    def dir
      _path                     = @task.path
      if _path.class == Script  #scripts use the alphanunderscrore name for the directory
        _dir                    = "#{ Job.dir }/#{ @task.stage.id }/script/#{ _path.name }"
      else
        _dir                    = "#{ Job.dir }/#{ @task.id }"
      end
      _dir
    end

    def path_dir
      _path_dir                 = @task.dir.dirname
      return                      _path_dir
    end

    def refresh_dir
      @task.dir.rm_r
      @task.dir.mkdir_p
      Log.write                   "Refreshed task dir " + @task.dir
    end

    def purge_dir
      @task.dir.rm_r
      @task.dir.mkdir_p
      Log.write                   "Purged task dir "    + @task.dir
    end

    def create_dir
      @task.dir.mkdir_p
     Log.write                   "Created task dir "   + @task.dir
    end

    def purge!
      @task.delete
      Log.write "Purged task #{ @task.id }"
    end
  end
end
