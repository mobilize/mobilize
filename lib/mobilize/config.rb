module Mobilize
  class Config < Settingslogic
    source "#{File.expand_path("~/.mob.yml")}"
    namespace ENV['MOBILIZE_ENV'] || "development"
  end
end
mob_yml_path = File.expand_path("~/.mob.yml")
unless File.exists?(mob_yml_path)
  FileUtils.cp("#{Mobilize.root}/samples/mob.yml",mob_yml_path)
  Mobilize::Logger.info("Wrote default configs to ~/.mob.yml, please add environment variables accordingly")
end
