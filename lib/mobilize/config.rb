require "settingslogic"
require 'fileutils'
module Mobilize
  class Config < Settingslogic
    def Config.dir;                "#{Mobilize.home_dir}/config";end
    def Config.path;               "#{Config.dir}/config.yml";end
    def Config.key_dir;            "#{Mobilize.home_dir}/keys";end

    #load settingslogic
    source Config.path

    namespace ENV['MOBILIZE_ENV'] || "development"

    #generates a yml configuration file 
    #based on hash provided
    def Config.write_from_hash(file_name, hash)
      @file                   = File.open File.expand_path(file_name), "w"
      @file.print               hash.to_yaml
      @file.close
      return true
    end
    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_from_sample(file_name, force = nil)
      @file_name              = file_name
      @source_path            = "#{Mobilize.root}/samples/#{@file_name}"
      @target_path            = "#{Config.dir}/#{@file_name}"

      FileUtils.mkdir_p         File.dirname @target_path

      @force_write            = (File.exists?(@target_path) and force == true)
      if                        @force_write or !File.exists?(@target_path)
        FileUtils.cp            @source_path, @target_path
        Mobilize::Logger.info   "Wrote default to #{@target_path}, " +
                                "please add environment variables accordingly"
      end
    end
    #loads rc file from home directory if present
    def Config.load_rc
      env_file                    = "#{Config.dir}/mobrc"
      if File.exists?               env_file
        env_vars                  = File.readlines env_file
        env_vars.each             do |env_var|
          export_key,value          = env_var.split("=")
          if export_key[0..5]      == "export"
            key                     = export_key.split(" ").last
            ENV[key]                = value.strip
          end
        end
      end
    end
    def Config.write_key_files
      FileUtils.mkdir_p            Config.key_dir
      Config.write_box_file     if Mobilize.config.box.private_key_path
      Config.write_git_files    if Mobilize.config.github.owner_ssh_key_path
      return true
    end
    def Config.write_box_file
      @box_ssh_path           = "#{Config.key_dir}/box.ssh"
      FileUtils.cp              Mobilize.config.box.private_key_path,
                                @box_ssh_path
      FileUtils.chmod           0700, @box_ssh_path
      Logger.info               "Wrote box ssh file"
    end
    def Config.write_git_files
      @git_ssh_path           = "#{Config.key_dir}/git.ssh"
      FileUtils.cp              Mobilize.config.github.owner_ssh_key_path,
                                @git_ssh_path

      #set git to not check strict host
      @git_sh_path           = "#{Config.key_dir}/git.sh"
      @git_sh_cmd            = "#!/bin/sh\nexec /usr/bin/ssh " +
                                "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                "-i #{@git_ssh_path} \"$@\""

      File.write                @git_sh_path, @git_sh_cmd

      FileUtils.chmod           0700, [@git_sh_path, @git_ssh_path]
      Logger.info               "Wrote git ssh files"
      return                    true
    end
  end
end
