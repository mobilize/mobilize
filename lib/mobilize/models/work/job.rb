module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field      :name,             type: String
    field      :active,           type: Boolean
    field      :user_id,          type: String
    field      :_id,              type: String, default:->{"#{user_id}/#{name}"}
    belongs_to :user
    belongs_to :box
    has_one    :trigger
    has_many   :stages
    has_many   :tasks

    after_initialize :set_self
    def set_self; @job = self;end

    def Job.dir
      "#{Mobilize.home_dir}/jobs"
    end

    def Job.purge!
      Job.dir.rm_r
    end

    def Job.perform( _job_id )
         @job                   = Job.find _job_id
      if @job.trigger.tripped?
         _stage                 = @job.next_stage
         Resque.enqueue_by        :mobilize, Stage, _stage.id
      end
    end

    def working?
      _next_stage                = @job.next_stage
      return                       _next_stage.working? if _next_stage
    end

    def parent
      _trigger                   = @job.trigger
      if _trigger.parent_job_id
        _parent_job              = Job.find _trigger.parent_job_id
        return                     _parent_job
      end
    end

    def next_stage
      _stages                   = @job.stages.sort_by { |_stage| _stage.order }
      _next_stage               = _stages.select { |_stage| !_stage.complete? }.first
      return                      _next_stage
    end

    def complete
      @job.update_status         :completed
    end

    def fail
      @job.update_status         :failed
    end

    def purge!
      @job.stages.each { |_stage| _stage.purge! }
      @job.delete
      Log.write "Purged job #{ @job.id }"
    end
  end
end
