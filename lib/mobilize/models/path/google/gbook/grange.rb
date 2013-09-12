module Mobilize
  class GrangePath < GfilePath
    include Mongoid::Document
    include Mongoid::Timestamps
  end
end
