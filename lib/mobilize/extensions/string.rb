class String
  def to_a
    return [self]
  end
  def oputs
    STDOUT.puts self
  end
  def eputs
    STDERR.puts self
  end
  def opp
    pp self
  end
  def to_md5
    Digest::MD5.hexdigest(self)
  end
  def popen4(except=true,log=false)
    str = self
    out_str,err_str = []
    puts str if log
    status = Open4.popen4(str) do |pid,stdin,stdout,stderr|
      out_str = stdout.read
      err_str = stderr.read
    end
    exit_status = status.exitstatus
    raise err_str if (exit_status !=0 and except==true)
    return out_str
  end
  def escape_regex
    str = self
    new_str = str.clone
    char_string = "[\/^$. |?*+()"
    char_string.chars.to_a.each{|c|
    new_str.gsub!(c,"\\#{c}")}
    new_str
  end
  #makes everything alphanumeric
  #except spaces, slashes, and underscores
  #which are made into underscores
  def alphanunderscore
    str = self
    str.gsub(/[^A-Za-z0-9_ \/]/,"").gsub(/[ \/]/,"_")
  end
  def norm_num
    return self.gsub(",","").gsub("$","").gsub("%","").gsub(" ","")
  end
  def is_float?
    return self.norm_num.to_f.to_s == self.norm_num.to_s
  end
  def is_fixnum?
    return self.norm_num.to_i.to_s == self.norm_num.to_s
  end
  def json_to_hash
    begin
      return JSON.parse(self)
    rescue => exc
      exc = nil
      return {}
    end
  end
  def tsv_to_hash_array
    rows = self.split("\n")
    return [] if rows.first.nil?
    return [{rows.first=>nil}] if (rows.length==2 and rows.second==nil)
    headers = rows.first.split("\t")
    if rows.length==1
      #return single member hash with all nil values
      return [headers.map{|k| {k=>nil}}.inject{|k,h| k.merge(h)}]
    end
    row_hash_arr =[]
    rows[1..-1].each do |row|
      cols = row.split("\t")
      row_hash = {}
      headers.each_with_index{|h,h_i| row_hash[h] = cols[h_i]}
      row_hash_arr << row_hash
    end
    return row_hash_arr
  end
  def tsv_header_array(delim="\t")
    str = self
    #up to right before first line break, or whole thing
    str[0..(str.index("\n") || 0)-1].split(delim)
  end
end
