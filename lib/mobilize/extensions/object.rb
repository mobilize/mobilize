class Object
  #abbreviate instance_eval
  def ie(&blk)
    _obj = self
    _obj.instance_eval(&blk)
  end
  def send_w_retries(_method_name, *_args, &blk)
    _obj            = self
    _total_retries   = Mobilize.config.object.send_total_retries
    _sleep_time      = Mobilize.config.object.send_sleep_time
    _result         = nil
    _exc            = nil
    _current_retries = 0
    _identifier      = "#{_obj.to_s} #{_method_name.to_s}"
    _success         = false

    while _current_retries < _total_retries and _success == false

      begin
        _result               = _obj.send(_method_name, *_args, &blk)
        _success               = true
      rescue => _exc
        _current_retries      += 1
        Mobilize::Logger.write "Failed #{_identifier} with #{_exc.to_s}; " + 
                               "Sleeping for #{_sleep_time.to_s}"
        
        sleep                  _sleep_time
        Mobilize::Logger.write "Retrying #{_identifier}; " + 
                               "#{_current_retries.to_s} of #{_total_retries.to_s} time(s)"
      end

    end

    if _success==false
      Mobilize::Logger.write  "Unable to #{identifier} with: #{@exc.to_s}", "FATAL"
    end

    return _result
  end
end
