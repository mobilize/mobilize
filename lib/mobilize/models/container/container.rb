module Mobilize
  class Container
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
    field :node_name, type: String
    field :image_name, type: String
  end
end
