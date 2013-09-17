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

    def home_dir
      @user = self
      return "/home/#{@user.ssh_name}"
    end
  end
end
