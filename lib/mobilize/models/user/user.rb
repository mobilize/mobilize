module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active, type: Boolean
    field :google_login, type: String
    field :_id, type: String, default:->{ google_login} #name@domain
    field :github_login, type: String
    validates :active, presence: true
    belongs_to :ec2
    has_many :jobs

    def ssh_name
      return self.id.gsub("@","-")
    end
  end
end
