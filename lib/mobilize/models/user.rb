module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active,       type: Boolean
    field :google_login, type: String
    field :github_login, type: String
    field :_id,          type: String, default:->{ google_login.alphanunder } #name_domain
    has_many :crontabs
  end
end
