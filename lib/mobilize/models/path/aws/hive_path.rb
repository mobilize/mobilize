module Mobilize
  class HivePath < AwsPath
    include Mongoid::Document
    include Mongoid::Timestamps
    field :hdfs_path, type: String #uniquely identifies dst and handler

  end
end
