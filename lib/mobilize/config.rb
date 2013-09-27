module Mobilize
  class Config < Settingslogic
    source "#{Mobilize.root}/config/mob.yml"
    namespace ENV['MOBILIZE_ENV'] || "development"
    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_sample(file_name,force=nil)
      target_dir = File.expand_path("~/.mobilize")
      FileUtils.mkdir_p(target_dir)
      source_path = "#{Mobilize.root}/samples/#{file_name}"
      config_path = "#{Mobilize.root}/config/#{file_name}"
      target_path = "#{target_dir}/#{file_name}"
      if (File.exists?(target_path) and force==true) or 
        !File.exists?(target_path)
        FileUtils.cp(source_path,target_path)
        FileUtils.ln_s(target_path,config_path, force: true)
        Mobilize::Logger.info("Wrote default to #{target_path}, " + 
                              "and added symlink in #{config_path}, " +
                              "please add environment variables accordingly")
      end

    end

    def Config.write_resque_pool(force=nil)

    end
  end
end
