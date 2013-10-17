module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field :name,             type: String
    field :active,           type: Boolean
    field :user_id,          type: String
    field :_id,              type: String, default:->{"#{user_id}/#{name}"}
    belongs_to :user
    belongs_to :box
    has_one :trigger
    has_many :stages
    has_many :tasks

    def Job.dir
      "#{Mobilize.home_dir}/jobs"
    end

    def Job.purge!
      FileUtils.rm_r "#{Mobilize.home_dir}/jobs", force: true
    end

    def Job.perform(job_id)
         @job                   = Job.find job_id
      if @job.trigger.tripped?
         @stage                 = @job.next_stage
         Resque.enqueue_by        :mobilize, Stage, @stage.id
      end
    end

    def working?
      @job                       = self
      @next_stage                = @job.next_stage
      return                       @next_stage.working? if @next_stage
    end

    def parent
      @job                       = self
      @trigger                   = @job.trigger
      if @trigger.parent_job_id
        @parent_job              = Job.find(@trigger.parent_job_id)
        return                     @parent_job
      end
    end

    def next_stage
      @job                      = self
      @stages                   = @job.stages.sort_by{|stage| stage.order}
      @next_stage               = @stages.select{|stage| !stage.complete? }.first
      return                      @next_stage
    end

    def complete
      @job                      = self
      @job.update_status         :completed
    end

    def fail
      @job                      = self
      @job.update_status         :failed
    end
  end
end
