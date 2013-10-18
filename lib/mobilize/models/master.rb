module Mobilize
  module Master
    @@config                                     = Mobilize.config "master"
    def Master.config;                             @@config;end

    def Master.start_workers

      #stop and restart resque workers
      @args                       = []
      Mobilize::Cli.resque          @args, stop: true
      Mobilize::Cli.resque          @args
      sleep 5
      @test_workers               = Resque.workers.select {|worker|
                                                            true if worker.queues.first == Mobilize.queue
                                                          }.compact

      @resque_pool_yml            = File.expand_path(Mobilize.home_dir) +
                                    "/resque-pool.yml"

      @resque_pool_config         = YAML.load_file @resque_pool_yml

      @num_workers                = @resque_pool_config[Mobilize.env][Mobilize.queue]

      Mobilize::Logger.write(       "Could not start resque workers", "FATAL") unless @test_workers.length == @num_workers
    end

    def Master.stop

    end

    def Master.restart

    end

    def Master.queued_payloads

    end

    def Master.working_payloads

    end

    def Master.workers

    end

    def Master.working_sessions

    end

    def Master.queue

    end

    def Master.clear_queue

    end

    def Master.kill(payload_id)

    end
  end
end
