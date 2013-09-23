module GoogleDrive
  class ClientLoginFetcher
    #this is patched to handle server errors due to http chaos
    def request_raw(method, url, data, extra_header, auth)
      @clf = self
      uri = URI.parse(url)
      timeout = Mobilize.config.google.api.timeout
      @response = nil
      current_retries = 0
      identifier = "Google API #{method.to_s} #{url.to_s} #{extra_header.to_s}" 
      success = false
      while success == false
        #instantiate http object, set params
        http = @proxy.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        #set 600  to allow for large downloads
        http.read_timeout = timeout
        Mobilize::Logger.info(identifier)
        @response = @clf.http_call(http, method, uri, data, extra_header, auth)
        current_retries,success = resolve_response(@response,current_retries)
      end
      return response
    end
    def http_call(http, method, uri, data, extra_header, auth)
      timeout = Mobilize.config.google.api.timeout
      http.read_timeout = timeout
      http.start() do
        path = uri.path + (uri.query ? "?#{uri.query}" : "")
        header = auth_header(auth).merge(extra_header)
        if method == :delete || method == :get
          http.__send__(method, path, header)
        else
          http.__send__(method, path, data, header)
        end
      end
    end
    def resolve_response(response,current_retries)
      total_retries = Mobilize.config.google.api.total_retries
      sleep_time = Mobilize.config.google.api.sleep_time
      success = false
      if response.nil? or response.code.starts_with?("4")
        Mobilize::Logger.info("#{identifier} failed with #{@response.body}; retrying in #{sleep_time.to_s}")
        sleep sleep_time
        current_retries += 1
      elsif response.code.starts_with?("5")
        exponential_sleep_time = sleep_time * (curr_retries*curr_retries)
        current_retries += 1
        Mobilize::Logger.info("#{identifier} failed with #{response.body}; retrying in #{exponential_sleep_time.to_s}")
        sleep exponential_sleep_time
      else
        Mobilize::Logger.info("#{identifier} returned #{response.body}")
        success = true
      end
      if success==false and current_retries == total_retries
        Mobilize::Logger.error("Unable to #{identifier} with #{response.body}")
      end
      return [current_retries,success]
    end
  end
end
