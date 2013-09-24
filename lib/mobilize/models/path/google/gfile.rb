module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :key, type: String
    field :name, type: String
    field :owner, type: Array
    field :readers, type: Array
    field :writers, type: Array
    field :_id, type: String, default:->{"gfile://#{owner}/#{name}"}

    @@config = Mobilize.config

    def Gfile.get_password(email)
      if email == @@config.google.owner.email
        password = @@config.google.owner.password
        Logger.info("Got password for google owner email #{email}")
      else
        password = @@config.google.worker.accounts.select{|w| w.email == email}.first
        Logger.error("Could not find password for email #{email}") unless password
        Logger.info("Got password for google worker email #{email}")
      end
      return password
    end

    def Gfile.login(email=@@config.google.owner.email)
      password = Gfile.get_password(email)
      @session = ::GoogleDrive.login(email,password)
      Logger.info("Logged into Google Drive.")
      return @session
    end

    def Gfile.remotes_by_name(name,session)
      @session = session
      @remotes = @session.files(title: name, "title-exact" => "true")
      Logger.info("found #{remotes.length.to_s} remotes by name #{name}")
      return @remotes
    end

    def Gfile.remotes_by_owner(email,session)
      @session = session
      @remotes = @session.files(owner: email)
      Logger.info("found #{remotes.length.to_s} remotes by owner #{email}")
      return @remotes
    end

    def Gfile.remotes_by_owner_and_name(email,name,session)
      @session = session
      @remotes = @session.files(owner: email, title: name, "title-exact" => "true")
      return @remotes
    end

    def find_or_create_remote(session)
      @gfile = self
      @session = session
      #create remote file with a blank string if there isn't one
      @remote = @gfile.remote(@session) || @session.upload_from_string("",@gfile.name)
      @gfile.sync(rem)
      return @rem
    end

    def remote(session)
      @gfile = self
      @session = session
      @remotes = Gfile.remotes_by_owner_and_name(@gfile.owner_email,@gfile.name,@session)
      if @remotes.length>1
        if @gfile.key
          @remote = @remotes.select{|r| r.resource_id == @gfile.key}.first
        end
        if @rem
          Logger.info("You have #{remotes.length} remotes owned by #{@gfile.owner_email} and named #{@gfile.name};" +
                      " you should delete all incorrect versions."
                     )
        else
          Logger.error("There are #{remotes.length} remotes owned by #{@gfile.owner_email} and named #{@gfile.name}" + 
                       " and no local key; you should delete all incorrect versions."
                      )
        end
      elsif @remotes.length == 1
        @remote = @remotes.first
        Logger.info("Remote #{rem.resource_id} found, assigning to #{@gfile.id}")
      elsif @remotes.empty?
        @remote = nil
      end
      return @rem
    end

    def sync(session)
      @session = session
      @gfile = self
      @remote = @gfile.remote(@session)
      acls = @remote.acl.to_enum.to_a
      roles = {owner: [], reader: [], writer: []}
      acls.each do |a|
        scope = if a.scope.nil?
                  a.with_key ? "link" : "everyone"
                else
                  a.scope
                end
        roles[a.role.to_sym] << scope
      end
      @gfile.update_attributes(
        name: @remote.title,
        key: @remote.resource_id,
        owner: roles[:owner].first,
        readers: roles[:reader],
        writers: roles[:writer]
      )
      return @remote
    end

    def read(session,user,dir)
      @gfile = self
      @session = session
      @user = user
      @remote = @gfile.sync(@session)
      if @gfile.readers.include?(@user.id)
        gdrive_dir = "#{dir}/gdrive"
        FileUtils.mkdir_p(gdrive_dir)
        gdrive_file = "#{gdrive_dir}/#{@gfile.name}"
        @remote.download_to_file(gdrive_file)
        Logger.info("Downloaded #{gdrive_file} from #{@gfile.id}")
      else
        Logger.error("User #{@user.id} does not have read access to #{@gfile.id}")
      end
    end

    def write(session,user,file)
      @session = session
      @gfile = self
      @user = user
      @remote = @gfile.sync(@session)
      if @gfile.writers.include?(@user.id)
        @remote.update_from_file(file)
        Logger.info("Uploaded #{file} from #{@gfile.id}")
      else
        Logger.error("User #{@user.id} does not have write access to #{@gfile.id}")
      end
    end
  end
end
