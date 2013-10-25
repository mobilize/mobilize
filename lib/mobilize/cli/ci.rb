require 'base64'
module Mobilize
  module Cli
    module Ci
      def Ci.perform(_args)
        _operator                       = _args[1]
        Ci.send                           _operator, _args
      end
      #takes the given prefix, decodes it, decrypts it, writes it to
      #the home folder with <prefix>_<env>.ssh
      def Ci.decode(_args)
      _file_name                       = _args[2]
      #gather all of these prefixes from ENV
        _base64_chunks                 = {}
        ENV.each do |_key, _value|
          _key_start                   = _key[0.._file_name.length-1]
          if _key_start               == _file_name
            _base64_chunks[_key]       = _value
          end
        end

        _base64_file_str               = _base64_chunks.sort_by{|_base64_chunk|
                                                                 _base64_chunk.first #key
                                                          }.map{|_base64_chunk|
                                                                 _base64_chunk.last  #value
                                                          }.join

        _file_string                   = Base64.strict_decode64 _base64_file_str
        File.write                       _file_name, _file_string
      end

      def Ci.encode(_args)
        _file_path                       = _args[2]
        _prefix                          =  File.basename(_file_path)
        _repo                            = "mobilize/mobilize"
        _file_str                        = File.read( File.expand_path _file_path)
        _base64_file_str                 = Base64.strict_encode64 _file_str
        _base64_chars                    = _base64_file_str.chars.to_a
        _base64_slices                   = _base64_chars.each_slice(100).to_a #100 char chunks
        _base64_chunks                   = _base64_slices.map {|_slice| _slice.join }

        _base64_chunks.each_with_index do |_chunk, _chunk_i|
          _chunk_pad_i                   = "%02d" % _chunk_i
          _chunk_name                    = "#{_prefix}_#{_chunk_pad_i}"
          _cmd                           = "travis encrypt -r #{_repo} #{_chunk_name}=#{_chunk}"
          puts                             "##{_chunk_name}\n  - secure: " + `#{_cmd}`
        end
      end
    end
  end
end
