class Object
  #abbreviate instance_eval
  def ie(&blk)
    obj = self
    obj.instance_eval(&blk)
  end
  def send_w_retries(method_name, *args,&blk)
    @obj = self
    total_retries = Mobilize.config.object.send_total_retries
    sleep_time = Mobilize.config.object.send_sleep_time
    @result = nil
    @exc = nil
    curr_retries = 0
    identifier = "#{@obj.to_s} #{method_name.to_s}"
    success = false
    while curr_retries < total_retries and success == false
      begin
        @result = @obj.send(method_name,*args,&blk)
        success = true
      rescue => @exc
        curr_retries += 1
        Mobilize::Logger.info("Failed #{identifier} with #{@exc.to_s}; Sleeping for #{sleep_time.to_s}")
        sleep sleep_time
        Mobilize::Logger.info("Retrying #{identifier}; #{curr_retries.to_s} of #{total_retries.to_s} time(s)")
      end
    end
    if success==false
      Mobilize::Logger.error("Unable to #{identifier} with: #{@exc.to_s}")
    end
    return @result
  end
end
