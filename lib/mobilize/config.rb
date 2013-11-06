require "settingslogic"
require 'fileutils'
require 'mongoid'
require 'tempfile'
module Mobilize
  def Mobilize.db
    Mongoid.session( :default )[ :database ].database
  end
  def Mobilize.root
    _file = __FILE__
    _file = File.expand_path _file
    _file = File.expand_path "#{ _file }/../../.."
    _file
  end
  def Mobilize.env
    ENV[ 'MOBILIZE_ENV' ] || "test"
  end
  def Mobilize.home_dir
    File.expand_path "~/.mobilize"
  end
  def Mobilize.config_dir
    "#{ Mobilize.home_dir }/config"
  end
  def Mobilize.queue
    "mobilize-#{ Mobilize.env }"
  end
  def Mobilize.console
    require 'mobilize'
    Mobilize.pry
  end
  def Mobilize.revision
    _revision_path = "#{ Mobilize.root }/REVISION"
    _revision_path.exists? ? File.read( _revision_path ) : "HEAD"
  end

  class Config < Settingslogic
    def Config.dir;                "#{ Mobilize.home_dir }/config";end
    def Config.path;               "#{ Config.dir }/config.yml";end
    def Config.key_dir;            "#{ Mobilize.home_dir }/keys";end

    #load settingslogic
    source Config.path

    namespace Mobilize.env

    #generates a yml configuration file
    #based on hash provided
    def Config.write_from_hash( _file_name, _hash )
      File.write               File.expand_path( _file_name ), _hash.to_yaml
      return true
    end
    #takes file from samples, copies to ~/.mobilize,
    #creates symlink in config/
    def Config.write_from_sample( _file_name, _force = nil )
      _source_path            = "#{ Mobilize.root }/samples/#{ _file_name }"
      _target_path            = "#{ Config.dir }/#{ _file_name }"

      FileUtils.mkdir_p         File.dirname( _target_path )

      _force_write            = ( File.exists? _target_path and _force == true )
      if                        _force_write or !File.exists? _target_path
        FileUtils.cp            _source_path, _target_path
        puts                    "Wrote default to #{ _target_path }, " +
                                "please add environment variables accordingly"
      end
    end
    #loads rc file from home directory if present
    def Config.load_rc
      _env_file                    = "#{ Config.dir }/mobrc"
      if File.exists? _env_file
        _env_vars                  = File.readlines _env_file
        _env_vars.each             do |_env_var|
          _export_key, _value       =  _env_var.split "="
          if _export_key[0..5]     ==  "export"
            _key                    = _export_key.split( " " ).last
            ENV[_key]               = _value.strip
          end
        end
      end
    end
    def Config.write_key_files
      Config.key_dir.mkdir_p
      Config.write_box_file     if Mobilize.config.cluster.box.private_key_path
      Config.write_git_files    if Mobilize.config.github.owner_ssh_key_path
      return true
    end
    def Config.write_box_file
      _box_ssh_path           = "#{ Config.key_dir }/box.ssh"
      _private_key_path       = Mobilize.config.cluster.box.private_key_path
      _private_key_path.cp      _box_ssh_path
      _box_ssh_path.chmod       0700
      puts                      "Wrote box ssh file"
    end
    def Config.write_git_files
      _git_ssh_path           = "#{ Config.key_dir }/git.ssh"
      _owner_ssh_key_path     = Mobilize.config.github.owner_ssh_key_path
      _owner_ssh_key_path.cp    _git_ssh_path

      #set git to not check strict host
      _git_sh_path           = "#{ Config.key_dir }/git.sh"
      _git_sh_cmd            = "#!/bin/sh\nexec /usr/bin/ssh " +
                                "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                                "-i #{ _git_ssh_path } \"$@\""

      _git_sh_path.write        _git_sh_cmd

      _git_sh_path.chmod        0700
      _git_ssh_path.chmod       0700
      puts                      "Wrote git ssh files"
      return                    true
    end

    def Config.connect_mongodb
      _mongoid_config_file   = Tempfile.new "mongodb"
      begin
      _mongoid_config_path   = _mongoid_config_file.path
      _Mongodb               = Mobilize.config.mongodb

      _mongoid_config_hash   = { Mobilize.env => {
                                 'sessions'   =>
                               { 'default'    =>
                               {
                                 'username'             => _Mongodb.username,
                                 'password'             => _Mongodb.password,
                                 'database'             => _Mongodb.database || "mobilize-#{ Mobilize.env }",
                                 'persist_in_safe_mode' => true,
                                 'hosts'                => _Mongodb.hosts.split( "," )
                               }
                               }
                               }}

      Mobilize::Config.write_from_hash    _mongoid_config_path, _mongoid_config_hash
      Mongoid.load!                       _mongoid_config_path, Mobilize.env
      FileUtils.rm_r                      _mongoid_config_path
      rescue                           => _exc
        puts                              "Unable to load Mongoid with current configs: #{ _exc.to_s }, #{ _exc.backtrace.to_s }"
      ensure
        _mongoid_config_file.unlink
      end
    end
  end
end
