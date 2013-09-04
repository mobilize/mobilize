module Mobilize
  class Transfer
    include Mongoid::Document
    include Mongoid::Timestamps
    field :from_url, type: String #uniquely identifies
    field :to_url, type: String
    field :container, type: String
    field :command, type: String
    field :stage_id, type: String
    field :status, type: String
    field :started_at, type: Time
    field :completed_at, type: Time
    field :failed_at, type: Time

  end
end
