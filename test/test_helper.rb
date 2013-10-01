require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname(File.expand_path(__FILE__))
#set test environment
ENV['MOBILIZE_ENV'] = 'test'
require 'mobilize'
#drop test database
Mongoid.purge!
#stop and restart resque workers
Mobilize::Cli.resque([],stop: true)
Mobilize::Cli.resque([])
sleep 5
test_workers = Resque.workers.map do |w|
  w if w.queues.first=="mobilize-test"
end.compact
Mobilize::Logger.error("Could not start resque workers") unless test_workers.length==5
#define convenience methods for initializing test objects
module TestHelper
  def TestHelper.ec2(name)
    return Mobilize::Ec2.find_or_create_by(name: name)
  end
  def TestHelper.ssh(ec2)
    ec2.sshs.find_or_create_by(
      ec2_id: ec2.id,
      user_name: Mobilize.config.minitest.ssh.user_name,
      private_key_path: Mobilize.config.minitest.ssh.private_key_path
    )
  end
  def TestHelper.user(ec2)
    Mobilize::User.find_or_create_by(
      active: true,
      google_login: Mobilize.config.minitest.google.email,
      github_login: Mobilize.config.minitest.github.login,
      ec2_id: ec2.id
    )
  end
  def TestHelper.gfile
    Mobilize::Gfile.find_or_create_by(
    owner: Mobilize.config.minitest.google.email,
    name: "test_file"
    )
  end
  def TestHelper.github_public
    return Mobilize::Github.find_or_create_by(
             owner_name: Mobilize.config.minitest.github.public.owner_name,
             repo_name: Mobilize.config.minitest.github.public.repo_name,
           )
  end
  def TestHelper.github_private
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
      Logger.info("missing private github params, returning nil for @github_private")
      return nil
    end
  end
  def TestHelper.job(user)
    user.jobs.create(user_id: user.id, name: "test_job")
  end
  def TestHelper.task(job,path,call,session,args={})
    @task = job.tasks.find_or_create_by(
      job_id: job.id, path_id: path.id, call: call
    )
    @task.session = session
    @task.update_attributes(args)
    @task
  end
end
