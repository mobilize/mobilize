require 'mobilize'
module Mobilize
  module Cli
    module Log
      def Log.perform(_args)
             _operator            = _args[1]
        if   _operator           == 'tail'

             _condition           = _args[2..3].reject {|_arg| _arg.nil? or  _arg.is_integer? }.first
             _limit               = _args[2..3].select {|_arg| _arg      and _arg.is_integer? }.first

             _condition           = YAML.easy_load( _condition) if _condition            
             _limit               = _limit.abs                  if _limit 
             
             _op_args             = [ _condition, _limit ].compact

             Mobilize::Log.tail     _op_args
        else
          
             Mobilize::Log.send     _operator
        end
      end
    end
  end
end
