require "settingslogic"
require 'fileutils'
module Mobilize
  def Mobilize.db
    Mongoid.session(:default)[:database].database
  end
  def Mobilize.root
    File.expand_path "#{File.dirname(File.expand_path(__FILE__))}/../.."
  end
  def Mobilize.env
    ENV['MOBILIZE_ENV'] || "test"
  end
  def Mobilize.home_dir
    File.expand_path "~/.mobilize"
  end
  def Mobilize.config_dir
    "#{Mobilize.home_dir}/config"
  end
  def Mobilize.log_dir
    "#{Mobilize.home_dir}/log"
  end
  def Mobilize.queue
    "mobilize-#{Mobilize.env}"
  end
  def Mobilize.console
    require 'mobilize'
    Mobilize.pry
  end
  def Mobilize.revision
    _revision_path = "#{Mobilize.root}/REVISION"
    File.exists?(_revision_path) ? File.read(_revision_path) : "HEAD"
  end

  class Config < Settingslogic
    def Config.dir;                "#{Mobilize.home_dir}/config";end
    def Config.path;               "#{Config.dir}/config.yml";end
    def Config.key_dir;            "#{Mobilize.home_dir}/keys";end

    #load settingslogic
    source Config.path

    namespace Mobilize.env

    #generates a yml configuration file 
    #based on hash provided
    def Config.write_from_hash(_file_name, _hash)
      _file                   = File.open File.expand_path(_file_name), "w"
      _file.print               _hash.to_yaml
      _file.close
      return true
    end
    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_from_sample(_file_name, _force = nil)
      _source_path            = "#{Mobilize.root}/samples/#{_file_name}"
      _target_path            = "#{Config.dir}/#{_file_name}"

      FileUtils.mkdir_p         File.dirname _target_path

      _force_write            = (File.exists?(_target_path) and _force == true)
      if                        _force_write or !File.exists?(_target_path)
        FileUtils.cp            _source_path, _target_path
        puts                    "Wrote default to #{_target_path}, " +
                                "please add environment variables accordingly"
      end
    end
    #loads rc file from home directory if present
    def Config.load_rc
      _env_file                    = "#{Config.dir}/mobrc"
      if File.exists?               _env_file
        _env_vars                  = File.readlines _env_file
        _env_vars.each             do |_env_var|
          _export_key, _value       =  _env_var.split("=")
          if _export_key[0..5]     ==  "export"
            _key                    = _export_key.split(" ").last
            ENV[_key]               = _value.strip
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
      _box_ssh_path           = "#{Config.key_dir}/box.ssh"
      FileUtils.cp              Mobilize.config.box.private_key_path,
                                _box_ssh_path
      FileUtils.chmod           0700, _box_ssh_path
      puts                      "Wrote box ssh file"
    end
    def Config.write_git_files
      _git_ssh_path           = "#{Config.key_dir}/git.ssh"
      FileUtils.cp              Mobilize.config.github.owner_ssh_key_path,
                                _git_ssh_path

      #set git to not check strict host
      _git_sh_path           = "#{Config.key_dir}/git.sh"
      _git_sh_cmd            = "#!/bin/sh\nexec /usr/bin/ssh " +
                                "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                "-i #{_git_ssh_path} \"$@\""

      File.write                _git_sh_path, _git_sh_cmd

      FileUtils.chmod           0700, [_git_sh_path, _git_ssh_path]
      puts                      "Wrote git ssh files"
      return                    true
    end
  end
end
