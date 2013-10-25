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

    def Job.dir
      "#{Mobilize.home_dir}/jobs"
    end

    def Job.purge!
      FileUtils.rm_r Job.dir, force: true
    end

    def Job.perform(_job_id)
         _job                   = Job.find _job_id
      if _job.trigger.tripped?
         _stage                 = _job.next_stage
         Resque.enqueue_by        :mobilize, Stage, _stage.id
      end
    end

    def working?
      _job                       = self
      _next_stage                = _job.next_stage
      return                       _next_stage.working? if _next_stage
    end

    def parent
      _job                       = self
      _trigger                   = _job.trigger
      if _trigger.parent_job_id
        _parent_job              = Job.find(_trigger.parent_job_id)
        return                     _parent_job
      end
    end

    def next_stage
      _job                      = self
      _stages                   = _job.stages.sort_by{|stage| stage.order}
      _next_stage               = _stages.select{|stage| !stage.complete? }.first
      return                      _next_stage
    end

    def complete
      _job                      = self
      _job.update_status         :completed
    end

    def fail
      _job                      = self
      _job.update_status         :failed
    end
  end
end
