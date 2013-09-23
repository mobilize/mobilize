module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :key, type: String
    field :_id, type: String, default:->{ key }
    field :name, type: String
    field :owner_email, type: Array
    field :reader_emails, type: Array
    field :writer_emails, type: Array
   
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

    def Gfile.files_by_name(name,session=nil)
      @session = session || Gfile.login
      files = @session.files(title: name, "title-exact" => "true")
      Logger.info("found #{files.length.to_s} files by name #{name}")
      return files
    end

    def Gfile.files_by_owner(email,session=nil)
      @session = session || Gfile.login
      files = @session.files(owner: email)
      Logger.info("found #{files.length.to_s} files by owner #{email}")
      return files
    end

    def acls(session=nil)
      return self.instance(session).acl.to_enum.to_a
    end

    def owner_acl(acls=nil)
      @acls = acls || @gfile.acls
    end

    def sync(session=nil)
      session ||= Gfile.login
      @gfile = self
      @acls = @gfile.acls
      @gfile.update_attributes(
        name: @gfile.title,
        owner_email: @gfile.owner(@acls),
        reader_emails: @gfile.readers(@acls),
        writer_emails: @gfile.writers(@acls)
      )
    end

    def reader_acls(session=nil)
      @gfile = self
      @session ||= Gfile.login
    end

    def writer_acls(session=nil)
      @gfile = self
      @session ||= Gfile.login
    end
  end
end
