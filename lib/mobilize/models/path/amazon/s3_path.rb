module Mobilize
  #an S3Path resolves to a file or folder inside
  #ENV['MOB_S3_BUCKET']
  class S3Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
  end
end
