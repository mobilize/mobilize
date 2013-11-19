class Time
  def Time.alphanunder_now
    _fraction           = Time.now.utc.to_f.to_s.split( "." ).last[ 0..5 ]
    Time.now.utc.strftime "%Y_%m_%d_%H_%M_%S_#{ _fraction }_utc"
  end
end
