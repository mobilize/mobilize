module Mobilize
  #an engine is an Ssh instance that runs resque workers
  class Engine < Ssh
    include Mongoid::Document
    include Mongoid::Timestamps

    def setup
      @engine                           = self
      @engine.install_mobilize
    end
  end
end
