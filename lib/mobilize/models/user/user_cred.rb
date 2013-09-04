module Mobilize
  class UserCred
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :service, type: String
    field :key, type: String #e.g. ssh_private_key, user_name, password, secret_key
    field :value, type: String
  end
end
