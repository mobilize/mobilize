module Mobilize
  class Ec2Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :service, type: String, default:->{"ec2"}
    field :container_name, type: String
    field :file_path, type: String
  end
end
