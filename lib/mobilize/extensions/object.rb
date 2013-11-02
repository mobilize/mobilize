class Object
  #abbreviate instance_eval
  def ie(&blk)
    _obj = self
    _obj.instance_eval(&blk)
  end
  def send_w_retries(_method_name, *_args, &blk)
    _obj, _result, _exc, _success         = self, nil, nil, false
    _current_retries                      = 0
    _total_retries                        = Mobilize.config.object.send_total_retries
    _sleep_time                           = Mobilize.config.object.send_sleep_time
    _identifier                           = "#{_obj.to_s} #{_method_name.to_s}"

    while _current_retries < _total_retries and _success == false

      begin
        _result                           = _obj.send _method_name, *_args, &blk
        _success                          = true
      rescue                             => _exc
        _current_retries                 += 1
        Mobilize::Log.write                "Failed #{_identifier} with #{_exc.to_s}; " + 
                                           "Sleeping for #{_sleep_time.to_s}", "ERROR"
        
        sleep                                _sleep_time
        Mobilize::Log.write                "Retrying #{_identifier}; " + 
                                           "#{_current_retries.to_s} of #{_total_retries.to_s} time(s)"
      end
    end

    unless _success;                       Mobilize::Log.write( "Unable to #{_identifier} with: #{_exc.to_s}", "FATAL");end

    _result
  end
end
