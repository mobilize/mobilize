module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active, type: Boolean
    field :google_login, type: String
    field :_id, type: String, default:->{ google_login} #name@domain
    field :github_login, type: String
    field :ec2_public_key, type: String
    validates :active, presence: true
  end
end
