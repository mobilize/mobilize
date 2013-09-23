require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname(File.expand_path(__FILE__))
#set test environment
ENV['MOBILIZE_ENV'] = 'test'
require 'mobilize'
#drop test database
Mongoid.purge!
module TestHelper
  def TestHelper.ec2
    return Mobilize::Ec2.new(name: @worker_name)
  end
  def TestHelper.github_pub
    return Mobilize::Github.find_or_create_by(
             owner_name: Mobilize.config.minitest.github.public.owner_name,
             repo_name: Mobilize.config.minitest.github.public.repo_name,
           )
  end
  def TestHelper.user(ec2)
    Mobilize::User.find_or_create_by(
      active: true,
      google_login: Mobilize.config.minitest.google.login,
      github_login: Mobilize.config.minitest.github.login,
      ec2_id: ec2.id
    )
  end
  def TestHelper.github_priv
    domain = Mobilize.config.minitest.github.private.domain
    owner_name = Mobilize.config.minitest.github.private.owner_name
    repo_name = Mobilize.config.minitest.github.private.repo_name
    if domain and owner_name and repo_name
      return Mobilize::Github.find_or_create_by(
        domain: domain,
        owner_name: owner_name,
        repo_name: repo_name
      )
    else
      Logger.info("missing private github params, returning nil for @github_priv")
      return nil
    end
  end
  def TestHelper.job(user,github)
    Mobilize::Job.find_or_create_by(
      user_id: user.id,
      command: "ls @path",
      path_ids: [github.id],
      gsubs: {"@path"=>"mobilize"}
    )
  end
end
