module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String

  end
end
