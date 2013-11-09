module Mobilize
  class Crontab
    include Mongoid::Document
    include Mongoid::Timestamps
    field      :user_id,   type: String
    field      :name,      type: String
    field      :gbook_id,  type: String
    field      :_id,       type: String, default:->{ gbook_id }
    belongs_to :user
    has_many   :crons
  end
end
