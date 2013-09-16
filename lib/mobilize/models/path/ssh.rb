module Mobilize
  class Ssh
    include Mongoid::Document
    include Mongoid::Timestamps
    #ssh resolves to an ssh instance in a user's home dir for a given ec2 node
    field :ec2_id, type: String
    field :user_id, type: String
    field :_id, type: String, default:->{ "#{ec2_id}:#{user_ssh_name}" }

    #after_create :find_or_create_home

    def user_ssh_name
      @ssh = self
      return @ssh.user_id.gsub("@","-")
    end

    def ec2
      @ssh = self
      Ec2.find(@ssh.ec2_id)
    end

    def user
      @ssh = self
      User.find(@ssh.user_id)
    end

    def home_dir
      @ssh = self
      return "/home/#{@ssh.user_ssh_name}"
    end

    #logs into the instance using the owner account
    def login
      @ssh = self
      @ec2 = @ssh.ec2
      @session = Net::SSH.start(@ec2.dns,ENV['MOB_EC2_ROOT_USER'],:keys=>ENV['MOB_EC2_PRIV_KEY_PATH'])
      Logger.info("Started SSH session for #{@user.id} on #{@ec2.name}")
      return @session
    end

    #gets a list of transfers for
    #this user on this ec2
    def transfers(limit=50)
      @ssh = self
      Transfer.where(ssh_id: @ssh.id).to_a
    end
  end
end
