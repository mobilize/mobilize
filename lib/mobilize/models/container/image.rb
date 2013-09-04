module Mobilize
  class Image
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
  end
end
