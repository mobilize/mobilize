module Mobilize
  class Ssh < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_name, type: String #username for box
    field :private_key_path, type: String
    field :ec2_id, type: String #needed for id
    field :home_dir, type: String, default:->{"/home/#{user_name}"}
    field :_id, type: String, default:->{"ssh/#{ec2_id}/#{user_name}"}
    belongs_to :ec2

    def input(task)
      @task = task
      @task.worker.refresh
      @task.worker.purge
      File.open("#{@task.worker.dir}","w") {|f| f.print(@task.input)}
      Logger.info("wrote input into worker at #{@task.worker.dir}")
    end

    def Ssh.session
      "session"#placeholder
    end

    def run(task)
      @ssh     = self
      @task    = task
      @ssh.input(@task)
      #deploy ssh command to cache
      @task.deploy
      #cd to job dir and execute file from there
      exec_cmd = "(cd #{@task.cache.dir}/ && sh in) > " +
                 "#{@task.cache.dir}/out 2> " +
                 "#{@task.cache.dir}/err; echo $? > sig"
      @ssh.sh(exec_cmd)
      return true
    end

    def result(task)
      @ssh          = self
      @task         = task
      delim         = "MOBILIZE_SSH_RESULT_DELIMITER"
      result_cmd    = "'cd #{@task.cache.dir} && array=(in out err sig) " +
                      "&& (for each in $array;do;:;cat $each;echo \"#{delim}\";done)'"
      result_string = @ssh.sh(result_cmd)[:stdout]
      stdin, out,err,sig = result_string.split(delim)
      return {in: stdin, out: out, err: err, sig: sig}
    end

    def sh(command,except=true)
      @ssh = self
      ssh_args = {keys: [@ssh.private_key_path],paranoid: false}
      @result = Net::SSH.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |ssh|
        ssh.run(command,except)
      end
      return @result
    end

    def cp(loc_path, rem_path)
      @ssh = self
      ssh_args = {keys: [@ssh.private_key_path],paranoid: false}
      @result = Net::SCP.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |scp|
        scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
          Logger.info("#{name}: #{sent}/#{total}")
        end
      end
      return @result
    end
  end
end
