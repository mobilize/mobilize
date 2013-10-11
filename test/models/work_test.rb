require "test_helper"
class WorkTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @Fixture                      = Mobilize::Fixture
    @github_public                = @Fixture::Github.public
    @worker_name                  = @Fixture::Ec2.worker_name
    @ec2                          = @Fixture::Ec2.default    @worker_name
    @ec2_session                  = Mobilize::Ec2.session
    @ec2.find_or_create_instance    @ec2_session
    @user                         = @Fixture::User.default   @ec2
    @ssh                          = @Fixture::Ssh.default    @ec2
    @ssh_session                  = Mobilize::Ssh.session
    @github_session               = Mobilize::Github.session
    @job                          = @Fixture::Job.default    @user
    @stage01                      = @Fixture::Stage.default  @job, 1, "read"
    @stage02                      = @Fixture::Stage.default  @job, 2, "run"
    @stage03                      = @Fixture::Stage.default  @job, 3, "write"
    @github_public_task           = @Fixture::Task.default   @job,
                                                             @github_public,
                                                             @github_session
    input_cmd                     = "(echo 'log this to the log' > log) && ls path1"
    @ssh_task                     = @Fixture::Task.default   @job, @ssh, @ssh_session,
                                                                 input: input_cmd,
                                                                 subs: {
                                                                 path1: @github_public_task.cache.dir
                                                                       }
    @gfile_write_task             = @Fixture::Task.default   @job, @gfile, @gfile_session,
                                                                 input: @ssh_task.worker.dir
  end

  def test_perform

  end
end
