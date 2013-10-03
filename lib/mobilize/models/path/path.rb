module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.
    #
    def kind
      self.class.to_s.downcase.split("::").last
    end
  end
end
