module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Status
    field :name,             type: String
    field :active,           type: Boolean
    field :user_id,          type: String
    field :_id,              type: String, default:->{"#{user_id}/#{name}"}
    belongs_to :user
    has_one :trigger
    has_many :stages
    has_many :tasks

    def Job.perform(job_id)
         @job   =          Job.find job_id
      if @job.trigger.tripped?
         @stage =          @job.next_stage
         Resque.enqueue_by :mobilize, Stage, @stage.id
      end
    end

    def working?
      @job   = self
      @tasks = @job.tasks
      if @tasks.map{|task| task.working?}.include?(true)
        return true
      end
    end

    def parent
      @job     = self
      @trigger = @job.trigger
      if @trigger.parent_job_id
        return Job.find(@trigger.parent_job_id)
      else
        return nil
      end
    end
  end
end
