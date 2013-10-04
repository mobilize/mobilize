module Mobilize
  #used to patch status fields to job, stage, task
  module Status
    extend ActiveSupport::Concern
    included do
      field :started_at,   type: Time
      field :completed_at, type: Time
      field :failed_at,    type: Time
      field :retried_at,   type: Time
      field :status_at,    type: Time
      field :status,       type: String
      field :retries,      type: String
    end
  end
end