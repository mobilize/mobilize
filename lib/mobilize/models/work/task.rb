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
      _task = self
      return nil unless _task.subs
      _task.subs.each do |k,v|
        _string1                = Regexp.escape(k.to_s) # escape any special characters
        _string2                = Regexp.escape(v.to_s).gsub("/","\\/") #also need to manually escape forward slash
        _replace_cmd            = "cd #{_task.dir} && " +
                                  "(find . -type f \\( ! -path '*/.*' \\) | " + #no hidden folders in relative path
                                  "xargs sed -ie 's/#{_string1}/#{_string2}/g')"
        _replace_cmd.popen4
        Logger.write              "Replaced #{_string1} with #{_string2} in #{_task.dir}"
      end
    end

    def Task.perform(task_id)
      _task                      = Task.find(task_id)
      _path                      = _task.path
      _session                   = _path.class.session
      if                           _session
        _task.start
        begin
          _stage                 = _task.stage
          _path.send               _stage.call, _task
          _task.complete
        rescue                  => _exc
          if                       _task.retries < @@config.max_retries
            Logger.write           "Failed #{_task.id} with #{_exc.to_s}", "ERROR"
            _task.retry
          else
            _task.fail
          end
        end
      else
        Logger.write               "No session available for #{_task.id}"
      end
    end

    def working?
      _task                  = self
      _workers               = Resque.workers
      _workers.index         {|worker|
        _payload             = worker.job['payload']
        if _payload
          _work_id           = _payload['args'].first
          _working           = true if _work_id == _task.id
        end
        _working
                             }
      _working
    end

    def queued?
      _task                  = self
      _queued_jobs           = ::Resque.peek(Mobilize.queue,0,0).to_a
      _queued_jobs.index     {|job|
        _work_id             = job['args'].first
        @queued              = true if _work_id == _task.id
                              }
      @queued
    end

    def retry
      _task                  = self
      _task.update_attributes  retries: _task.retries + 1
      Resque.enqueue_to        Mobilize.queue, Task, _task.id
    end

    def start
      _task                   = self
      _task.update_status       :started
    end

    def complete
      _task                   = self
      _task.update_status       :completed
    end

    def fail
      _task                   = self
      _task.update_status     = :failed
      _stage                  = _task.stage
      _stage.fail
    end

    def dir
      _task                     = self
      _path                     = _task.path
      if _path.class == Script  #scripts use the alphanunderscrore name for the directory
        _dir                    = "#{Job.dir}/#{_task.stage.id}/script/#{_path.name}"
      else
        _dir                    = "#{Job.dir}/#{_task.id}"
      end
      _dir
    end

    def path_dir
      _task                     = self
      _path_dir                 = File.dirname _task.dir
      return                      _path_dir
    end

    def refresh_dir
      _task                     = self
      FileUtils.rm_r              _task.dir, force: true
      FileUtils.mkdir_p           _task.dir
      Logger.write                "Refreshed task dir " + _task.dir
    end

    def purge_dir
      _task                     = self
      FileUtils.mkdir_p           _task.dir
      FileUtils.rm_r              _task.dir, force: true
      Logger.write                "Purged task dir "    + _task.dir
    end

    def create_dir
      _task                     = self
      FileUtils.mkdir_p           _task.dir
      Logger.write                "Created task dir "   + _task.dir
    end
  end
end
