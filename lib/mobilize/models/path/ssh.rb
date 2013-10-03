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
      File.open("#{@task.job.cache}/stdin","w") {|f| f.print(@task.input)}
      Logger.info("wrote input into job cache stdin for #{@task.id}")
    end

    def Ssh.session
      "session"#placeholder
    end

    def run(task)
      @ssh = self
      @task = task
      #job worker directory to server
      @ssh.input(@task)
      exec_cmd = "(cd #{@ssh.cache(@task)} && sh stdin) > " +
                 "#{@ssh.cache(@task)}/stdout 2> " +
                 "#{@ssh.cache(@task)}/stderr"
      @ssh.sh(exec_cmd)
      return true
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
