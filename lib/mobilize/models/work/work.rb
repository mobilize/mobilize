module Mobilize
  #used to patch status fields to job, stage, task
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
      field :retries,             type: Fixnum, default:->{0}
      field :max_retries,         type: Fixnum, default:->{Mobilize.config.job.max_retries}
      field :retry_delay,         type: Fixnum, default:->{Mobilize.config.job.retry_delay}
    end

    def update_status(status)
      @work                     = self
      @status_string            = status.to_s
      @timestamp_string         = @status_string + "_at"
      @current_time             = Time.now.utc

      @work.update_attributes     @timestamp_string =>     @current_time,
                                  status:                  @status_string,
                                  status_at:               @current_time

      Logger.info                 "#{@work.id} status: #{@work.status} " +
                                  "at #{@work.send @timestamp_string}"
    end
  end
end
