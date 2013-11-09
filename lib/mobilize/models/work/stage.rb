module Mobilize
  #a stage defines a set of tasks that must be completed before the next stage can begin
  class Stage
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field :cron_id,    type: String
    field :order,      type: Fixnum, default:->{ 1 }
    field :call,       type: String #read, write, or run
    field :name,       type: String, default:->{ call + ("%02d" % order) }
    field :_id,        type: String, default:->{ "#{job_id}/#{name}" }
    belongs_to :cron
    has_many :tasks

    after_initialize :set_self
    def set_self; @stage = self; end

    def working?
      @stage              = self
      _tasks              = @stage.tasks
      if                    _tasks.index { |_task| _task.working? }
        return              true
      end
    end

    def perform
      @stage.update_status        :started
      _task_procs = @stage.tasks.map do |_task|
        Proc.new _task.perform
      end
      _task_procs.thread
    end

    def last?
      _job                  = @stage.job
      _max_order            = _job.stages.map { |_job_stage| _job_stage.order }.max
      return true          if @stage.order == _max_order
    end

    def complete
      @stage.update_status    :completed
      if                       @stage.last?
        _job                 = @stage.job
        _job.complete
      end
    end

    def fail
      @stage.update_status    :failed
      _job                   = @stage.job
      _job.fail
    end

    def purge!
      @stage.tasks.each { |_task| _task.purge! }
      @stage.delete
      Log.write "Purged stage #{ @stage.id }"
    end
  end
end
