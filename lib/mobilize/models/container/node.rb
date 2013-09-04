module Mobilize
  class Node
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
    field :dns, type: String
    field :internal_ip, type: String
    field :external_ip, type: String
  end
end
