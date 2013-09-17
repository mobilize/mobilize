class Object
  #abbreviate instance_eval
  def ie(&blk)
    obj = self
    obj.instance_eval(&blk)
  end
  def send_w_retries(method_name, *args,&blk)
    @obj = self
    total_retries = ENV['MOB_SEND_TOTAL_RETRIES'] || 5
    @result = nil
    @exc = nil
    curr_retries = 0
    identifier = "#{@obj.to_s} #{method_name.to_s}"
    while curr_retries < total_retries and @result.nil?
      begin
        @result = @obj.send(method_name,*args,&blk)
      rescue => @exc
        retries += 1
        Logger.info("Failed #{identifier} with #{@exc.to_s}")
        Logger.info("Retrying #{identifier}; #{curr_retries.to_s} of #{total_retries.to_s} time(s)")
      end
    end
    if @result.nil?
      Logger.error("Unable to #{identifier} with: #{@exc.to_s}")
    else
      Logger.info("Ran #{identifier} successfully with #{curr_retries} retries")
    end
    return @result
  end
end
