module Mobilize
  #a stage defines a set of tasks that must be completed before the next stage can begin
  class Stage
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field :cron_id,    type: String
    field :order,      type: Fixnum, default:->{ 1 }
    field :call,       type: String #read, write, or run
    field :name,       type: String, default:->{ "stage" + order.to_s }
    field :_id,        type: String, default:->{ "#{ cron_id }/#{ name }" }
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
      @stage.start
      _task_procs = @stage.tasks.map do |_task|
        Proc.new { _task.perform }
      end
      _results    = _task_procs.thread
      _failures   = _results.select do |_result|
                      _result.is_a? Exception
                    end
      if _failures.empty?
        @stage.complete
      end
    end

    def last?
      _cron                  = @stage.cron
      _max_order            = _cron.stages.map { |_cron_stage| _cron_stage.order }.max
      return true          if @stage.order == _max_order
    end

    def complete
      @stage.update_status    :completed
      if                       @stage.last?
        _cron                = @stage.cron
        _cron.complete
      end
    end

    def start
      @stage.update_status       :started
      @stage.tasks.each { |_task| _task.clear }
    end

    def fail
      @stage.update_status    :failed
      _cron                  = @stage.cron
      _cron.fail
      Log.write               "Failure; Check logs", "ERROR", @stage
    end

    def purge!
      @stage.tasks.each { |_task| _task.purge! }
      @stage.delete
      Log.write            "Purged", "INFO", @stage
    end
  end
end
