module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active, type: Boolean
    field :_id, type: String #name@domain
    field :is_owner, type: Boolean
    validates :active, presence: true

    #only allow one owner user
    validates :is_owner, acceptance: false, if: Proc.new { User.where(owner: true).first}

    #gives the ssh private key the user needs to interact w git
    def git_key
      u = self
      uc = UserCred.where(user_id: u.id, service: "git", key: "private_key").first
      uc.value if uc
    end
  end
end
