module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.

  end
end
