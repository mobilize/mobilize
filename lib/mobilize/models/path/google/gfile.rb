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

    @@config = Mobilize.config.google

    def Gfile.get_password(email)
      if email == @@config.owner.email
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
      elsif @remotes.length == 1
        @remote = @remotes.first
        Logger.info("Remote #{@remote.resource_id} found, assigning to #{@gfile.id}")
      elsif @remotes.empty?
        @remote = nil
      end
      return @remote
    end

    def sync(session)
      @session = session
      @gfile = self
      @remote = @gfile.remote(@session)
      Logger.error("Could not find remote for #{@gfile.id}") unless @remote
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

    def cache(task)
      @gfile = self
      @task = task
      return "#{@task.job.cache}/gfile/#{@gfile.name}"
    end

    def clear_cache(task)
      @gfile = self
      @task = task
      @gfile.purge_cache(@task)
      @gfile.create_cache(@task)
      Logger.info("Cleared cache for #{@task.id}")
    end

    def purge_cache(task)
      @gfile = self
      @task = task
      FileUtils.rm_r(@gfile.cache(@task),force: true)
      Logger.info("Purged cache for #{@task}")
    end

    def create_cache(task)
      @gfile = self
      @task = task
      FileUtils.mkdir_p(@gfile.cache(@task))
      #remove the actual directory so it can be written as file
      FileUtils.rm_r(@gfile.cache(@task),force: true)
      Logger.info("Created cache for #{@task}")
    end

    #delete remote, cache, and local db object
    def purge!(task)
      @gfile = self
      @task = task
      @remotes = Gfile.remotes_by_owner_and_name(@gfile.owner,@gfile.name,@task.session)
      @remotes.each do |remote|
        remote.delete
        Logger.info("Deleted remote #{remote.resource_id} for #{@gfile.id}")
      end
      @gfile.purge_cache(@task)
      @gfile.delete
      Logger.info("Purged #{@gfile.id} from DB")
      return true
    end

    def read(task)
      @gfile = self
      @task = task
      @user = @task.user
      @remote = @gfile.sync(@task.session)
      if @user.id == @gfile.owner or @gfile.readers.include?(@user.id)
        @gfile.clear_cache(@task)
        @remote.download_to_file(@gfile.cache(@task))
        Logger.info("Downloaded #{@gfile.cache(@task)} from #{@gfile.id}")
      else
        Logger.error("User #{@user.id} does not have read access to #{@gfile.id}")
      end
    end

    def write(task)
      @gfile = self
      @task = task
      @user = @task.user
      @remote = @gfile.find_or_create_remote(@task.session)
      if @user.id == @gfile.owner or @gfile.writers.include?(@user.id)
        @remote.update_from_file(@task.input)
        Logger.info("Uploaded #{@task.input} from #{@gfile.id}")
      else
        Logger.error("User #{@user.id} does not have write access to #{@gfile.id}")
      end
    end
  end
end
