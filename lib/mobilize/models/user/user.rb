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

    def home
      return "/home/#{self.ssh_name}/#{Mobilize.db.name}"
    end

    def transfers
      Transfer.where(user_id: self.id).to_a
    end

    def purge_orphan_transfers
      #deletes any transfers in the remote, but not in the database
      @user = self
      remotes = @user.ec2.ssh("ls #{@user.home}/transfers").split("\n")
      locals = @user.transfers.map{|t| t.name}
      remotes.reject{|r| locals.include?(r)}.each do |r|
        Transfer.new(name: r).purge!
      end
    end
  end
end
