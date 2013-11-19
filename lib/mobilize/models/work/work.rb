module Mobilize
  #used to patch methods and status fields to job, stage, task
  module Work
    extend ActiveSupport::Concern
    included do
      field :touched_at,          type: Time
      field :started_at,          type: Time
      field :completed_at,        type: Time
      field :failed_at,           type: Time
      field :retried_at,          type: Time
      field :status_at,           type: Time
      field :status,              type: String
      field :retries,             type: Fixnum, default:->{ 0 }
      field :max_retries,         type: Fixnum, default:->{ Mobilize.config.work.max_retries }
      field :retry_delay,         type: Fixnum, default:->{ Mobilize.config.work.retry_delay }
      field :timeout,             type: Fixnum, default:->{ Mobilize.config.work.timeout }
    end

    def clear
      _work                  = self
      _work.update_attributes( touched_at: nil, started_at: nil,
                               completed_at: nil, failed_at: nil,
                               retried_at: nil, status_at: nil,
                               status: nil, retries: 0 )

      Log.write                "cleared", "INFO", _work
    end

    def update_status( _status )
      _work                     = self
      _status_string            = _status.to_s
      _timestamp_string         = _status_string + "_at"
      _current_time             = Time.now.utc

      _work.update_attributes     _timestamp_string =>     _current_time,
                                  status:                  _status_string,
                                  status_at:               _current_time

      Log.write                   "status set to #{ _work.status }", "INFO", _work
    end

    def timed_out?
      _work                    = self
      Time.now.utc > _work.started_at + _work.timeout
    end

    def complete?
      _work                    = self
      _work.status            == "completed"
    end

    def failed?
      _work                    = self
      _work.status            == "failed"
    end
  end
end
