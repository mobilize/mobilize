require 'base64'
#the travis gem must be installed to make use of the encrypt command
module Mobilize
  module Travis
    #makes a base64 version of the file
    #splits into multiple rows
    #returns travis encryption strings w comments for each
    def Travis.base64_encode(file_path)
      file_str = File.read("#{file_path}")
      return Base64.strict_encode64(file_str)
    end

    def Travis.encrypt_multiline(base64_file_str,prefix,chunk_length,repo="mobilize/mobilize")
      base64_chunks = base64_file_str.chars.to_a.each_slice(chunk_length).to_a.map {|s| s.join }
      base64_chunks.each_with_index do |chunk,chunk_i|
        chunk_pad_i = "%02d" % chunk_i
        chunk_name="#{prefix}#{chunk_pad_i}"
        cmd="travis encrypt -r #{repo} #{chunk_name}=#{chunk}"
        puts "##{chunk_name}\n  - secure: " + `#{cmd}`
      end
    end

    def Travis.encode_and_encrypt(file_path, prefix, chunk_length=100)
      base64_file_str = base64_encode(file_path)
      return encrypt_multiline(base64_file_str,prefix,chunk_length)
    end

    #decode base64 strings into single file as specified by path
    def Travis.base64_decode(prefix,count,file_path=prefix)
      base64_file_str = (0..count).to_a.map do |chunk_i|
                        chunk_pad_i = "%02d" % chunk_i
                        chunk_name="#{prefix}#{chunk_pad_i}"
                        ENV[chunk_name]
                      end.join
      file_string = Base64.strict_decode64(base64_file_str)
      File.open(file_path,"w"){|f| f.print(file_string)}
      return true
    end
  end
end
