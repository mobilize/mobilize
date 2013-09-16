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
      @user = self
      return @user.id.gsub("@","-")
    end

    def ec2
      @user = self
      Ec2.find(@user.ec2_id)
    end

    #creates an account and home directory
    #on home ec2 node
    def find_or_create_home
      @user = self
      return "/home/#{@user.ssh_name}"
    end
  end
end
