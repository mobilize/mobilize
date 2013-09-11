module Mobilize
  # a HivePath resolves to a Hive table
  class HivePath
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String #<db_name>.<table_name>
  end
end
