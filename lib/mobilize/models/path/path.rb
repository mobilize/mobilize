module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.
    #only path subclasses are stored in the database
    field :service, type: String #pointer subclass; e.g. GitPath = "git"
    field :address, type: String #unique path in the context of the service, slash delimited
    field :url, type: String, default:->{ "#{service}://#{address}" } #unique identifier
    field :http_url, type: String #version of path that can be accessed in a browser (if available)
    index({ url: 1 }, { unique: true, name: "url_index" })

    validates :service, :address, :url, presence: true

    #reads data from path if defined
    def read
      path = self
      raise "No read method defined for #{path.class}"
    end

    #writes data to path if defined
    def write(data)
      path = self
      raise "No write method defined for #{path.class}"
    end

    #destroys path if defined
    def destroy!
      path = self
      raise "No destroy! method defined for #{path.class}"
    end
  end
end
