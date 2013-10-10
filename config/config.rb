require "settingslogic"
require 'fileutils'
module Mobilize
  class Config < Settingslogic
    @@dir                     = File.dirname File.expand_path(__FILE__)

    @@path                    = "#{@@dir}/mob.yml"

    #load settingslogic
    source @@path if File.exists?(@@path)

    namespace ENV['MOBILIZE_ENV'] || "development"

    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_sample(file_name, force = nil)
      @file_name              = file_name
      @abs_home_dir           = File.expand_path Mobilize.home_dir
      @source_path            = "#{@@dir}/../samples/#{@file_name}"
      @config_path            = "#{@@dir}/#{@file_name}"
      @target_path            = "#{@abs_home_dir}/#{@file_name}"

      FileUtils.mkdir_p         @abs_home_dir

      @force_write            = (File.exists?(@target_path) and force == true)
      if                        @force_write or !File.exists?(@target_path)
        FileUtils.cp            @source_path, @target_path
        FileUtils.ln_s          @target_path, @config_path, force: true
        Mobilize::Logger.info   "Wrote default to #{@target_path}, " +
                                "please add environment variables accordingly"
      end

      if                        !File.exists?(@config_path)
        FileUtils.ln_s          @target_path, @config_path, force: true
        Mobilize::Logger.info   "added symlink to #{@target_path} in #{@config_path}"
      end
    end
  end
end
