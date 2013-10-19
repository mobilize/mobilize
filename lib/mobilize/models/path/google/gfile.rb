module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :remote_id,   type: String
    field :name,        type: String
    field :owner,       type: Array
    field :readers,     type: Array
    field :writers,     type: Array
    field :_id,         type: String, default:->{"gfile/#{owner.alphanunderscore}/#{name}"}

    @@config             = Mobilize.config("google")

    def Gfile.get_password(email)

      @email             = email

      if @email         == @@config.owner.email
        @password        = @@config.owner.password
        Logger.write       "Got password for google owner email #{@email}"
      else
        @password        = @@config.worker.accounts.select{|w| w.email == @email}.first
        if @password
          Logger.write     "Got password for google worker email #{@email}"
        else
          Logger.write     "Could not find password for email #{@email}", "FATAL"
        end
      end
      @password
    end

    def Gfile.session(email = nil)

      @email          = @@config.owner.email
      @password       = Gfile.get_password @email

      @session        = ::GoogleDrive.login @email, @password

      Logger.write      "Logged into Google Drive."
      @session
    end

    def sync(remote, session)
      @gfile, @remote, @session       = self, remote, session

      @remote                         = @gfile.remote @session
      @roles                          = @gfile.roles @remote

      @gfile.update_attributes name:    @remote.title,
                               key:     @remote.resource_id,
                               owner:   @roles[:owner].first,
                               readers: @roles[:reader],
                               writers: @roles[:writer]
      @remote
    end

    #delete remote and local db object
    def terminate(session)
      @gfile, @session      = self, session
      @remote               = @gfile.remote
      Logger.write            "Deleting remote #{@remote.resource_id} for #{@gfile.id}"

      @remote.delete
      @gfile.delete
      Logger.write            "Purged #{@gfile.id} from DB"

      true
    end

    def launch(session)
      @gfile, @session            = self, session
      @remote                     = @session.upload_from_string "", @gfile.name
      Logger.write                  "Lauched remote #{@remote.resource_id} for #{@gfile.id}"
      @gfile.sync                   @remote, @session
    end

    def is_reader?(user)
      @gfile, @user               = self, user
      @is_reader                  = @user.google_login == @gfile.owner or
                                    @gfile.readers.include? @user.google_login
    end

    def is_writer?(user)
      @user, @gfile                = user, self
      @is_writer                   = @user.google_login == @gfile.owner or
                                     @gfile.writers.include?(@user.google_login)
    end

    def read(task)
      @gfile, @task, @user        = self, task, task.user

      @remote                     = @gfile.sync @task.session

      if @gfile.is_reader?          @user
        #make sure path exists but dir does not
        @task.refresh_dir

        @remote.download_to_file   "#{@task.dir}/stdout"
        Logger.write               "Downloaded #{@gfile.id} to #{@task.dir}/stdout"
        Logger.write               "#{@user.google_login}: #{File.size(@task.input).to_s} bytes", "STAT"
      else
        Logger.write               "User #{@user.id} does not have read access to #{@gfile.id}", "FATAL"
      end
    end

    def write(task)
      @gfile, @task, @user         = self, task, task.user

      @remote                      = @gfile.remote @task.session

      if @gfile.is_writer?           @user

        @remote.update_from_file     @task.input
        Logger.write                 "Uploaded #{@task.input} from #{@gfile.id}"
        Logger.write                 "#{@user.google_login}: #{File.size(@task.input).to_s} bytes", "STAT"
      else
        Logger.write                 "#{@user.google_login} does not have write access to #{@gfile.id}", "FATAL"
      end
      true
    end

    def Gfile.remotes_by(session, params = {})
      @session                             = session

      if params[:title]
        params["title-exact"]              = true
      end

      @remotes                             = @session.files params
      #sort by published date for seniority
      @remotes.sort_by {|remote|
                        @remote            = remote
                        @publish_element   = @remote.document_feed_entry.css("published")
                        @publish_timestamp = @publish_element.children.first.text
                        @publish_timestamp
                        }
    end

    #creates both file and its remote
    def Gfile.find_or_create_by_owner_and_name(owner, name, session)
      @owner, @name, @session     = owner, name, session

      @gfile                      = Gfile.find_or_create_by owner: @owner, name: @name

      @remote                     = @gfile.remote(@session) if @gfile.remote_id

      @remotes                    = if @remote.nil?
                                      Gfile.remotes_by @session, owner: @owner, title: @name
                                    end

      unless                        @remotes.empty?
        @remote                   = @remotes.first

        if                          @remotes.length > 1
        Logger.write(               "TOO MANY REMOTES: #{@remotes.length} remotes " +
                                    "by #{@gfile.owner} with name #{@gfile.name}", "WARN")
        end
      end

      if                            @remote
        @gfile.sync                 @remote
      else
        @gfile.launch               @session
      end
    end

    def remote(session)
      @gfile, @session    = self, session

      Logger.write(        "Gfile has no remote_id", "FATAL") unless @gfile.remote_id

      @remotes            = Gfile.remotes_by(@session,owner: @gfile.owner, title: @gfile.title)

      @remotes            = @remotes.select{|remote|
                                            @remote              = remote
                                            @remote.resource_id == @gfile.remote_id
                                           }
      @remotes.first
    end

    def roles(remote)
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
      @roles
    end
  end
end
