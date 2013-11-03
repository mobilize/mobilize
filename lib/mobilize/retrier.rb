module Mobilize
  class Retrier
    def initialize( _object, _method_name, _max_attempts = nil, _sleep_time = nil )
      @retrier                             = self
      @max_attempts                      ||= Mobilize.config.retrier.max_attempts
      @sleep_time                        ||= Mobilize.config.retrier.sleep_time
      @attempts, @object, @method_name     = 0, _object, _method_name
      @result, @exc, @success              = nil, nil, false
      @identifier                          = "#{ @object.to_s } #{ @method_name.to_s }"
    end
    def fire( *_args, &blk )
      while @attempts < @max_attempts and @success == false
        begin
          @result                          = @object.send @method_name, *_args, &blk
          @success                         = true
        rescue                            => @exc
          @current_retries                += 1
          @retrier.log "retry"
          sleep                              @sleep_time
        end
      end

      @retrier.log "failure" unless @success

      @result
    end
    def log( _state )
      if    _state == "retry"
        Mobilize::Log.write                    "Failed #{ @identifier } with #{ @exc.to_s }; " +
                                               "Sleeping for #{ @sleep_time.to_s } and retrying, " +
                                               "#{ @attempts.to_s } of #{ @max_attempts.to_s } time(s)",
                                               "ERROR"
      elsif _state == "failure"
        Mobilize::Log.write "Unable to #{ @identifier } with: #{ @exc.to_s }", "FATAL"
      end
    end
  end
end
