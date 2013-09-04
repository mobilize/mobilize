module Mobilize
  class Schedule
    include Mongoid::Document
    include Mongoid::Timestamps
    field :url
  end
end
