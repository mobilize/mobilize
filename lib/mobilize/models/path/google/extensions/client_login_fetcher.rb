module GoogleDrive
  class ClientLoginFetcher
    #this is patched to handle server errors due to http chaos
    def request_raw(_method, _url, _data, _extra_header, _auth)
      _fetcher                    = self
      _uri                        = URI.parse(url)
      _timeout                    = Mobilize.config.google.api.timeout
      _response                   = nil
      _current_retries            = 0
      _identifier                 = "Google API #{_method.to_s} #{_extra_header.to_s}"
      _success                    = false
      while                         _success == false
        #instantiate http object, set params
        _http                     = @proxy.new _uri.host, _uri.port
        _http.use_ssl             = true
        _http.verify_mode         = OpenSSL::SSL::VERIFY_NONE
        #set 600  to allow for large downloads
        _http.read_timeout        = _timeout
        Mobilize::Logger.write      _identifier
        _response                 = _fetcher.http_call _http, _method, _uri, _data, _extra_header, _auth
        _current_retries,_success = _fetcher.resolve_response _identifier, _response, _current_retries
      end
      _response
    end

    def http_call(_http, _method, _uri, _data, _extra_header, _auth)
      _fetcher                    = self
      _timeout                    = Mobilize.config.google.api.timeout
      _http.read_timeout          = _timeout

      _http.start do
        _path                     = _uri.path + (_uri.query ? "?#{_uri.query}" : "")
        _header                   = _fetcher.auth_header(_auth).merge(_extra_header)

        if                          _method == :delete || _method == :get
                                    _http.__send__(_method, _path, _header)
        else
                                    _http.__send__(_method, _path, _data, _header)
        end
      end
    end

    def resolve_response(_identifier, _response, _current_retries)
      _fetcher                    = self
      _total_retries              = Mobilize.config.google.api.total_retries
      _success                    = false
      if                            _response.nil? or _response.code.starts_with?("4") or
                                    _response.code.starts_with?("5")
        _current_retries          = _fetcher.exponential_retry _identifier, _response, _current_retries
      else
        _fetcher.mobilize_log     _identifier, _response, "success", _current_retries, 0
        _success                  = true
      end

      if                            _successo == false and _current_retries >= _total_retries
        _fetcher.mobilize_log       _identifier, _response, "fatal", _current_retries, 0
      end

      [_current_retries, _success]
    end

    def mobilize_log(_identifier, _response, _status, _current_retries, _time)
      _total_retries                    = Mobilize.config.google.api.total_retries
      _message                          = "#{_identifier} #{_status} with " +
                                          "#{_response.body.ellipsize(25)};"
      _message                         += if _current_retries > 0
                                            " retry #{_current_retries.to_s} of #{_total_retries.to_s}" +
                                            " in #{_time.to_s}"
                                          else
                                            ""
                                          end
      if                                  _status == "fatal"
        Mobilize::Logger.write            _message, "FATAL"
      else
        Mobilize::Logger.write            _message
      end
    end

    def exponential_retry(_identifier, _response, _current_retries)
      _fetcher                    = self
      _sleep_time                 = Mobilize.config.google.api.sleep_time
      _exponential_sleep_time     = _sleep_time * (_current_retries*_current_retries)
      _current_retries           += 1
      _fetcher.mobilize_log         _identifier, _response, "failed", _current_retries, _exponential_sleep_time
      sleep                         _exponential_sleep_time
      return                        _current_retries
    end
  end
end
