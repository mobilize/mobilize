module Mobilize
  #a stage defines a set of tasks that must be completed before the next stage can begin
  class Stage
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field :job_id,    type: String
    field :order,     type: Fixnum, default:->{ 1 }
    field :name,      type: String, default:->{ "stage" + ("%02d" % order) }
    field :call,      type: String #read, write, or run
    field :_id,       type: String, default:->{ "#{job_id}/#{name}" }
    belongs_to :job
    has_many :tasks

    def working?
      @stage              = self
      @tasks              = @stage.tasks
      if                    @tasks.index{|task| task.working?}
        return              true
      end
    end

    def Stage.perform(stage_id)
      sleep                     300
      @stage                     = Stage.find stage_id
      @stage.update_status        :started
      @tasks                     = @stage.tasks
      @tasks.each              do |task|
        unless task.working? or task.complete?
          Resque.enqueue_by       :mobilize, Task, task.id
        end
      end
    end

    def last?
      @stage                = self
      @job                  = @stage.job
      @max_order            = @job.stages.map{|stage| stage.order}.max
      return true          if @stage.order == @max_order
    end

    def complete
      @stage                 = self
      @stage.update_status    :completed
      if                       @stage.last?
        @job                 = @stage.job
        @job.complete
      end
    end

    def fail
      @stage                 = self
      @stage.update_status    :failed
      @job                   = @stage.job
      @job.fail
    end
  end
end
