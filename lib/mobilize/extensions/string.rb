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
    Digest::MD5.hexdigest self
  end
  #fires system command with full visibility into stdout and stderr
  #default returns stdout only
  #with option to return all streams in hash
  def popen4(except=nil,all_streams=nil)
    except              = true unless except == false
    all_streams       ||= false
    in_str              = self
    out_str,err_str     = []

    status              = Open4.popen4(in_str) do |pid,stdin,stdout,stderr|
                         out_str = stdout.read
                         err_str = stderr.read
                       end

    exit_status         = status.exitstatus

    if exit_status != 0 and
       except      == true

       Mobilize::Logger.write err_str, "FATAL"

    elsif all_streams == false

      return out_str

    else

      return {in: in_str,
              out: out_str,
              err: err_str}

    end
  end
  #returns a shortened version of the string with an ellipsis if appropriate
  def ellipsize(length, ellipsis="(...)")
    str               = self
    ellipsis          = "" unless str.length > length
    return              str[0..length-1] + " " + ellipsis
  end
  def escape_regex
    str         = self
    new_str     = str.clone
    char_string = "[\/^$. |?*+()"
    char_array  = char_string.chars.to_a
    char_array.each do |c|
    new_str.gsub! c,"\\#{c}"
    end
    return        new_str
  end
  #makes everything alphanumeric
  #except spaces, slashes, and underscores
  #which are made into underscores
  def alphanunderscore
    str          = self
    alphanum_str = str.gsub(/[^A-Za-z0-9_\.@ \/]/,"")
    under_str    = alphanum_str.gsub(/[ \/\.@]/,"_")
    return         under_str
  end
  def norm_num
    no_commas = self.gsub(",","")
    no_dollar = no_commas.gsub("$","")
    no_pct    = no_dollar.gsub("%","")
    no_spaces = no_pct.gsub(" ","")
    return      no_spaces
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
    rows    = self.split("\n")
    return  [] if rows.first.nil?

    if rows.length == 2 and rows.second == nil
      #single key from first row
      #with nil value since there is no second
      single_key = rows.first
      return  [
               {single_key => nil}
              ]
    end

    #get headers from first row
    headers = rows.first.split("\t")

    if rows.length==1
      #return single row hash array with all nil values
      return [headers.map{|k| {k=>nil}}.inject{|k,h| k.merge(h)}]
    end

    #otherwise apply header keys to each row of values
    row_hash_arr =[]
    rows[1..-1].each do |row|
      cols          = row.split("\t")
      row_hash      = {}
      headers       .each_with_index{|h,h_i| row_hash[h] = cols[h_i]}
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
