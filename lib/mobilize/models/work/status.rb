module Mobilize
  #used to patch status fields to job, stage, task
  module Status
    extend ActiveSupport::Concern
    included do
      field :touched_at,   type: Time
      field :started_at,   type: Time
      field :completed_at, type: Time
      field :failed_at,    type: Time
      field :retried_at,   type: Time
      field :status_at,    type: Time
      field :status,       type: String
      field :retries,      type: Fixnum, default:->{0}
      field :max_retries,  type: Fixnum, default:->{Mobilize.config.job.max_retries}
      field :retry_delay,  type: Fixnum, default:->{Mobilize.config.job.retry_delay}
    end
  end
end
