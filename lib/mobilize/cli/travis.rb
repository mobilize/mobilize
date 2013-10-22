require 'base64'
module Mobilize
  module Cli
    module Ci
      #takes the given prefix, decodes it, decrypts it, writes it to
      #the home folder with <prefix>_<env>.ssh
      def Ci.decode(_env_prefix, _opts = {})
      #gather all of these prefixes from ENV
        _encoded_envs                 = []
         ENV.each do |_key, _value|
                      _key_start          = _key[0.._env_prefix.length-1]
                   if _key_start         == _env_prefix
                      _encoded_envs[_key] = _value
                   end
                 end

         Ci.base64_decode _encoded_envs

      end

      def Ci.base64_encode(_file_path)

        _file_str             = File.read "#{_file_path}"

        Base64.strict_encode64 _file_str
      end

      def Ci.encrypt_file(_file_path,
                          _prefix        =  File.basename(_file_path),
                          _repo          = "mobilize/mobilize")
        _base64_file_str                 =  Ci.base64_encode _file_path
        _base64_chars                    = _base64_file_str.chars.to_a
        _base64_slices                   = _base64_chars.each_slice(100).to_a #100 char chunks
        _base64_chunks                   = _base64_slices.map {|_slice| _slice.join }

        _base64_chunks.each_with_index do |_chunk, _chunk_i|
          _chunk_pad_i                   = "%02d" % _chunk_i
          _chunk_name                    = "#{_prefix}_#{_chunk_pad_i}"
          _cmd                           = "travis encrypt -r #{_repo} #{_chunk_name}=#{_chunk}"
          Mobilize::Logger.write           "##{_chunk_name}\n  - secure: " + `#{_cmd}`
        end
      end

      #decode base64 strings into single file as specified by path
      def Ci.base64_decode(_prefix, _count, _file_path = prefix)

        _base64_file_str            = (0.._count).to_a.map do |_chunk_i|
                                        _chunk_pad_i = "%02d" % _chunk_i
                                        _chunk_name  = "#{_prefix}#{_chunk_pad_i}"
                                        ENV[_chunk_name]
                                      end.join

        _file_string                = Base64.strict_decode64 _base64_file_str
        File.write                    _file_path, _file_string
        true
      end

    end
  end
end
