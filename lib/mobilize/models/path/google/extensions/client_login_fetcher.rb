module GoogleDrive
  class ClientLoginFetcher
    #this is patched to handle server errors due to http chaos
    def request_raw(method, url, data, extra_header, auth)
      @clf                        = self
      @uri                        = URI.parse(url)
      @timeout                    = Mobilize.config.google.api.timeout
      @response                   = nil
      @current_retries            = 0
      @log_length                 = Mobilize.config.google.api.response_log_length
      @identifier                 = "Google API #{method.to_s} #{extra_header.to_s}"
      @success                    = false
      while                         @success == false
        #instantiate http object, set params
        @http                     = @proxy.new @uri.host, @uri.port
        @http.use_ssl             = true
        @http.verify_mode         = OpenSSL::SSL::VERIFY_NONE
        #set 600  to allow for large downloads
        @http.read_timeout        = @timeout
        Mobilize::Logger.info       @identifier
        @response                 = @clf.http_call @http, method, @uri, data, extra_header, auth
        @current_retries,@success = @clf.resolve_response @identifier, @response, @current_retries
      end
      return                        @response
    end

    def http_call(http, method, uri, data, extra_header, auth)
      @uri                        = uri
      @timeout                    = Mobilize.config.google.api.timeout
      @http                       = http
      @http.read_timeout          = @timeout
      @method                     = method

      @http.start() do
        @path                     = @uri.path + (@uri.query ? "?#{@uri.query}" : "")
        @header                   = auth_header(auth).merge(extra_header)

        if                          @method == :delete || @method == :get
                                    @http.__send__(@method, @path, @header)
        else
                                    @http.__send__(@method, @path, data, @header)
        end
      end
    end

    def resolve_response(identifier,response,current_retries)
      @identifier, @response,
      @current_retries            = identifier, response, current_retries
      @clf                        = self
      @total_retries              = Mobilize.config.google.api.total_retries
      @success                    = false
      if                            @response.nil? or @response.code.starts_with?("4")
        @clf.mobilize_log           @identifier, @response, "fatal", @current_retries, 0
      elsif                         @response.code.starts_with?("5")
        @current_retries          = @clf.exponential_retry @identifier, @response, @current_retries
      else
        @clf.mobilize_log           @identifier, @response, "success", @current_retries, 0
        @success                  = true
      end

      if                            @success==false and @current_retries >= @total_retries
        @clf.mobilize_log           @identifier, @response, "fatal", @current_retries, 0
      end

      return [@current_retries,@success]
    end

    def mobilize_log(identifier, response, status, current_retries, time)
      @identifier, @response, @status,
      @current_retries, @time           = identifier, response, status, current_retries, time
      @total_retries                    = Mobilize.config.google.api.total_retries
      @log_length                       = Mobilize.config.google.api.response_log_length
      @ellipsis                         = @log_length < @response.body.length ? "(...)" : ""
      @message                          = "#{@identifier} #{@status} with " +
                                          "#{@response.body[0..@log_length]}#{@ellipsis}; " +
                                          "retry #{@current_retries.to_s} of #{@total_retries.to_s} " +
                                          "in #{@time.to_s}"
      if                                  @status == "fatal"
        Mobilize::Logger.error            @message
      else
        Mobilize::Logger.info             @message
      end
    end

    def exponential_retry(identifier,response,current_retries)
      @identifier, @response,
      @current_retries            = identifier, response, current_retries
      @sleep_time                 = Mobilize.config.google.api.sleep_time
      @exponential_sleep_time     = @sleep_time * (@current_retries*@current_retries)
      @current_retries           += 1
      @clf.mobilize_log             @identifier, @response, "failed", @current_retries, @exponential_sleep_time
      sleep                         @exponential_sleep_time
      return                        @current_retries
    end
  end
end
