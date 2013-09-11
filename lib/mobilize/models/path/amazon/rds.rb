module Mobilize
  #an RdsPath resolves to an Amazon RDS database
  class RdsPath
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String #<db_name>.<table_name>
  end
end
