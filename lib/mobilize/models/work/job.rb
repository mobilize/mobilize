module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Status
    field :name,         type: String
    field :user_id,      type: String #need for id
    field :_id,          type: String, default:->{"#{user_id}/#{name}"}
    field :started_at,   type: Time
    field :completed_at, type: Time
    field :failed_at,    type: Time
    belongs_to :user
    has_many :tasks
  end

  def Job.perform(job_id)
       @job   = Job.find(job_id)
    if @job.is_due?
       @job.enqueue_tasks
    end
  end

  def enqueue_tasks
    @job   = self
    @tasks = @job.tasks.find_all_by(order: @job.current_order)
  end

  def is_due?

  end
end
