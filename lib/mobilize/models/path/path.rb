module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.
  end

  def kind
    self.class.to_s.downcase.split("::").last
  end
end
