module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
    field :user_id, type: String #need for id
    field :_id, type: String, default:->{"#{user_id}/#{name}"}
    field :started_at, type: Time
    belongs_to :user
    has_many :tasks
  end
end
