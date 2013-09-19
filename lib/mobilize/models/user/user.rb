module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active, type: Boolean
    field :google_login, type: String
    field :_id, type: String, default:->{ google_login} #name@domain
    field :github_login, type: String
    field :ec2_id, type: String
    validates :active, presence: true

    def ssh_name
      return self.id.gsub("@","-")
    end

    def ec2
      Ec2.find(self.ec2_id)
    end

    def jobs
      Job.where(user_id: self.id).to_a
    end
  end
end
