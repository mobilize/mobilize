module Mobilize
  #a task defines an item on a resque queue
  #that performs on behalf of a cron
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field      :input,    type: String #used by write tasks to specify input
    field      :subs,     type: Hash   #used by run tasks to sub input
    field      :stage_id, type: String #need for id
    field      :path_id,  type: String
    field      :order,    type: Fixnum, default:->{ 1 } #used for naming
    field      :name,     type: String, default:->{ "task" + ( "%02d" % order ) }
    field      :_id,      type: String, default:->{"#{ stage_id }/#{ name }"}
    belongs_to :stage
    belongs_to :path

    after_initialize :set_self
    def set_self; @task = self;end

    def cron
      self.stage.cron
    end

    def user
      self.cron.user
    end

    def source
      _orders                       = @task.input.gsub( "task", "" ).gsub( "stage", "" ).split( "/" )
      _stage_order, _task_order     = _orders.map { |_order| "%02d" % _order.to_i }
      _source_task                  = Task.find _id: "#{ @task.stage.cron.id }/stage#{ _stage_order }/task#{ _task_order }"
      return File.read                "#{ _source_task.dir }/stdout"
    end

    def target
      return File.read            "#{ @task.dir }/stdout"
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

    def perform
      _path                      = @task.path
      @task.start
      begin
        _stage                 = @task.stage
        _path.send               _stage.call, @task
        @task.complete
      rescue                  => _exc
        if                       @task.retries < Mobilize.config.work.max_retries
          Log.write              "Failed #{ @task.id } with #{ _exc.to_s }," +
                                 "retry #{ @task.retries } of #{ Mobilize.config.work.max_retries }", "ERROR"
          @task.retry
        else
          @task.fail
          return _exc
        end
      end
    end

    def retry
      @task.update_attributes  retries: @task.retries + 1
      @task.perform
    end

    def complete
      @task.update_status       :completed
    end

    def start
      @task.update_status       :started
    end

    def fail
      @task.update_status     :failed
      _stage                  = @task.stage
      _stage.fail
    end

    def dir
      _job        = @task.stage.cron.job
      "#{ _job.dir }/#{ @task.stage.name }/#{ @task.path.id }"
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
      Log.write                  "Purged task #{ @task.id }"
    end
  end
end
