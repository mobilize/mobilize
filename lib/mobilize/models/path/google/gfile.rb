module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :key, type: String
    field :name, type: String
    field :owner, type: Array
    field :readers, type: Array
    field :writers, type: Array
    field :_id, type: String, default:->{"gfile/#{owner.gsub(/[\.@]/,"_")}/#{name}"}

    @@config = Mobilize.config("google")

    def Gfile.get_password(email)
      if email  == @@config.owner.email
        password = @@config.owner.password
        Logger.info("Got password for google owner email #{email}")
      else
        password = @@config.worker.accounts.select{|w| w.email == email}.first
        Logger.error("Could not find password for email #{email}") unless password
        Logger.info("Got password for google worker email #{email}")
      end
      return password
    end

    def Gfile.session(email=@@config.owner.email)
      password = Gfile.get_password(email)
      @session = ::GoogleDrive.login(email,password)
      Logger.info("Logged into Google Drive.")
      return @session
    end

    def sync(session)
      @session = session
      @gfile   = self
      @remote  = @gfile.remote(@session)
      Logger.error("Could not find remote for #{@gfile.id}") unless @remote
      roles    = @gfile.remote_roles(@remote)
      @gfile.update_attributes(
        name: @remote.title,
        key: @remote.resource_id,
        owner: roles[:owner].first,
        readers: roles[:reader],
        writers: roles[:writer]
      )
      return @remote
    end

    #delete remote, worker, and local db object
    def purge!(task)
      @gfile   = self
      @task    = task
      @remotes = Gfile.remotes_by_owner_and_name(@gfile.owner,@gfile.name,@task.session)
      @remotes.each do |remote|
        remote.delete
        Logger.info("Deleted remote #{remote.resource_id} for #{@gfile.id}")
      end
      @task.worker.purge
      @gfile.delete
      Logger.info("Purged #{@gfile.id} from DB")
      return true
    end

    def read(task)
      @gfile  = self
      @task   = task
      @user   = @task.user
      @remote = @gfile.sync(@task.session)
      if @user.google_login == @gfile.owner or
         @gfile.readers.include?(@user.google_login)
        #make sure path exists but dir does not
        @task.worker.purge
        #in this case, directory is file name
        @remote.download_to_file(@task.worker.dir)
        Logger.info("Downloaded #{@gfile.id} to #{@task.worker.dir}")
        @task.deploy
      else
        Logger.error("User #{@user.id} does not have read access to #{@gfile.id}")
      end
    end

    def write(task)
      @gfile = self
      @task = task
      @user = @task.user
      @remote = @gfile.find_or_create_remote(@task.session)
      if @user.google_login == @gfile.owner or @gfile.writers.include?(@user.google_login)
        @remote.update_from_file(@task.input)
        Logger.info("Uploaded #{@task.input} from #{@gfile.id}")
      else
        Logger.error("User #{@user.id} does not have write access to #{@gfile.id}")
      end
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
      @gfile.sync(@session)
      return @remote
    end

    def remote(session)
      @gfile = self
      @session = session
      @remotes = Gfile.remotes_by_owner_and_name(@gfile.owner,@gfile.name,@session)
      if @remotes.length>1
        @remote = @gfile.resolve_remotes(@remotes)     
      elsif @remotes.length == 1
        @remote = @remotes.first
        Logger.info("Remote #{@remote.resource_id} found, assigning to #{@gfile.id}")
      elsif @remotes.empty?
        @remote = nil
      end
      return @remote
    end

    def resolve_remotes(remotes)
      @gfile = self
      @remotes = remotes
      if @gfile.key
        @remote = @remotes.select{|r| r.resource_id == @gfile.key}.first
      end
      if @remote
        Logger.info("You have #{@remotes.length} remotes owned by #{@gfile.owner} and named #{@gfile.name};" +
                    " you should delete all incorrect versions."
                   )
      else
        Logger.error("There are #{@remotes.length} remotes owned by #{@gfile.owner} and named #{@gfile.name}" + 
                     " and no local key; you should delete all incorrect versions."
                    )
      end
      return @remote
    end

    def remote_roles(remote)
      @remote = remote
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
      return roles
    end
  end
end
