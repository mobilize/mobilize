module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :key,         type: String
    field :name,        type: String
    field :owner,       type: Array
    field :readers,     type: Array
    field :writers,     type: Array
    field :_id,         type: String, default:->{"gfile/#{owner.gsub(/[\.@]/,"_")}/#{name}"}

    @@config     = Mobilize.config("google")

    def Gfile.get_password(email)
      @email             = email
      if @email         == @@config.owner.email
        @password        = @@config.owner.password
        Logger.info        "Got password for google owner email #{@email}"
      else
        @password        = @@config.worker.accounts.select{|w| w.email == @email}.first
        if @password
          Logger.info      "Got password for google worker email #{@email}"
        else
          Logger.error     "Could not find password for email #{@email}"
        end
      end
      return               @password
    end

    def Gfile.session(email = nil)
      @email          = @@config.owner.email
      @password       = Gfile.get_password @email
      @session        = ::GoogleDrive.login @email, @password
      Logger.info       "Logged into Google Drive."
      return            @session
    end

    def sync(session)
      @session               = session
      @gfile                 = self
      @remote                = @gfile.remote @session
      unless                   @remote
        Logger.error           "Could not find remote for #{@gfile.id}"
      end
      @roles                 = @gfile.remote_roles @remote
      @gfile.update_attributes name:    @remote.title,
                               key:     @remote.resource_id,
                               owner:   @roles[:owner].first,
                               readers: @roles[:reader],
                               writers: @roles[:writer]
      return                   @remote
    end

    #delete remote, worker, and local db object
    def purge!(task)
      @gfile                = self
      @task                 = task
      @remotes              = Gfile.remotes_by @task.session,
                                        owner: @gfile.owner,
                                        title: @gfile.name
      @remotes.each       do |remote|
        remote.delete
        Logger.info           "Deleted remote #{remote.resource_id} for #{@gfile.id}"
      end
      @task.worker.purge
      @gfile.delete
      Logger.info             "Purged #{@gfile.id} from DB"
      return                  true
    end

    def read(task)
      @gfile                      = self
      @task                       = task
      @user                       = @task.user
      @worker                     = @task.worker
      @remote                     = @gfile.sync @task.session
      @is_reader                  = @user.google_login == @gfile.owner or
                                    @gfile.readers.include? @user.google_login

      if @is_reader
         #make sure path exists but dir does not
         @worker.purge
         #in this case, directory is file name
         @remote.download_to_file   @worker.dir
         Logger.info                "Downloaded #{@gfile.id} to " +
                                    "#{@worker.dir}"
         @task.deploy
      else
        Logger.error                "User #{@user.id} does not have read access to #{@gfile.id}"
      end
    end

    def write(task)
      @gfile                       = self
      @task                        = task
      @user                        = @task.user
      @remote                      = @gfile.find_or_create_remote @task.session

      @is_writer                   = @user.google_login == @gfile.owner or
                                     @gfile.writers.include?(@user.google_login)

      if @is_writer
        @remote.update_from_file     @task.input
        Logger.info                  "Uploaded #{@task.input} from #{@gfile.id}"
      else
        Logger.error                 "User #{@user.id} does not have write access to #{@gfile.id}"
      end
    end

    def Gfile.remotes_by(session,params={})
      @session                    = session

      if params[:title]
        params["title-exact"]     = true
      end

      @remotes                    = @session.files params
      return                        @remotes
    end

    def find_or_create_remote(session)
      @gfile                      = self
      @session                    = session
      #create remote file with a blank string if there isn't one
      @remote                     = @gfile.remote(@session) || @session.upload_from_string("", @gfile.name)
      @gfile.sync                   @session
      return                        @remote
    end

    def remote(session)
      @gfile                      = self
      @session                    = session
      @remotes                    = Gfile.remotes_by @session,
                                              owner: @gfile.owner,
                                              title: @gfile.name

      if                            @remotes.length>1
        @remote                   = @gfile.resolve_remotes @remotes
      elsif                         @remotes.length == 1
        Logger.info                 "Remote #{@remotes.first.resource_id} found, " +
                                    "assigning to #{@gfile.id}"
        @remote                   = @remotes.first
      elsif                         @remotes.empty?
        @remote                   = nil
      end
      return                        @remote
    end

    def resolve_remotes(remotes)
      @gfile                      = self
      @remotes                    = remotes


      @remote                     = @remotes.select{|remote|
                                                     remote.resource_id == @gfile.key
                                                   }.first if @gfile.key

      @base_message               = "There are #{@remotes.length} remotes " +
                                    "owned by #{@gfile.owner} and named #{@gfile.name};"
      if @remote
        Logger.info                 @base_message + " you should delete all incorrect versions."
        return                      @remote
      else
        Logger.error                @base_message + " and no local key; you should delete all incorrect versions."
      end
    end

    def remote_roles(remote)
      @remote                    = remote
      @acls                      = @remote.acl.to_enum.to_a
      @roles                     = {owner: [], reader: [], writer: []}
      @acls.each                do |acl|
        @acl                     = acl
        @scope                   = if @acl.scope.nil?
                                      @acl.with_key ? "link" : "everyone"
                                   else
                                      @acl.scope
                                   end
        @sym_role                = @acl.role.to_sym
        @roles[@sym_role]       << @scope
      end
      return                       @roles
    end
  end
end
