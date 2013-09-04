module Mobilize
  class User
    include Mongoid::Document
    include Mongoid::Timestamps
    field :active, type: Boolean
    field :name, type: String
    field :domain, type: String #typically gmail.com or googlegroups.com
    field :_id, type: String, default:->{"#{name}@#{domain}"}
    field :is_owner, type: Boolean
    validates :name, :domain, :active, presence: true

    #only allow one owner user
    validates :is_owner, acceptance: false, if: Proc.new { User.where(owner: true).first}

    #gives the ssh private key the user needs to interact w git
    def git_key
      u = self
      uc = UserCred.where(user_id: u.id, service: "git", key:"ssh_private_key").first
      uc.value if uc
    end
  end
end
