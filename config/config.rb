require "settingslogic"
require 'fileutils'
module Mobilize
  class Config < Settingslogic
    @@dir = File.dirname(File.expand_path(__FILE__))
    @@home_dir = "~/.mobilize"
    def self.home_dir;@@home_dir;end
    @@path = "#{@@dir}/mob.yml"

    #load settingslogic
    source @@path if File.exists?(@@path)
    namespace ENV['MOBILIZE_ENV'] || "development"

    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_sample(file_name,force=nil)
      abs_home_dir = File.expand_path(@@home_dir)
      FileUtils.mkdir_p(abs_home_dir)
      source_path = "#{@@dir}/../samples/#{file_name}"
      config_path = "#{@@dir}/#{file_name}"
      target_path = "#{abs_home_dir}/#{file_name}"
      if (File.exists?(target_path) and force==true) or 
        !File.exists?(target_path)
        FileUtils.cp(source_path,target_path)
        FileUtils.ln_s(target_path,config_path, force: true)
        Mobilize::Logger.info("Wrote default to #{target_path}, " +
                              "please add environment variables accordingly")
      end
      if !File.exists?(config_path)
        FileUtils.ln_s(target_path,config_path, force: true)
        Mobilize::Logger.info("added symlink to #{target_path} in #{config_path}")
      end
    end
  end
end
