module Mobilize
  module Master
    @@config                                     = Mobilize.config "master"
    def Master.config;                             @@config;end

    def Master.start_workers

      #stop and restart resque workers
      _args                       = []
      Mobilize::Cli.resque          _args, stop: true
      Mobilize::Cli.resque          _args
      sleep 5
      _test_workers               = Resque.workers.select {|_worker|
                                                            true if _worker.queues.first == Mobilize.queue
                                                          }.compact

      _resque_pool_yml            = File.expand_path(Mobilize.home_dir) +
                                    "/resque-pool.yml"

      _resque_pool_config         = YAML.load_file _resque_pool_yml

      _num_workers                = _resque_pool_config[Mobilize.env][Mobilize.queue]

      Mobilize::Log.write(          "Could not start resque workers", "FATAL") unless _test_workers.length == _num_workers
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
