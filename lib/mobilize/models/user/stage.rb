module Mobilize
  class Stage
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_name, type: String
    field :schedule_name, type: String
    field :job_name, type: String
    field :name, type: String
    field :index, type: String
    field :path, type: String, default: ->{ "#{user_name}/#{schedule_name}/#{job_name}/#{index}" }
    field :image, type: String #image to run in
    field :command, type: String #command to execute
    field :targets, type: Array #file urls to write
    field :status, type: String
    field :started_at, type: Time
    field :completed_at, type: Time
    field :failed_at, type: Time
  end
end
