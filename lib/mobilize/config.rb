module Mobilize
  class Config < Settingslogic
    source "#{File.expand_path("~/.mob.yml")}"
    namespace ENV['MOBILIZE_ENV'] || "development"
  end
end
