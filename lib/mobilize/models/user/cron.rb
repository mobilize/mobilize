module Mobilize
  class Cron
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: String
    field :name, type: String
    field :active, type: Boolean
    field :trigger, type: String

    def transfers
      Transfer.where(cron_id: self.id).to_a
    end

    def parent
      @cron = self
      if @cron.trigger.strip[0..4].downcase == "after"
        parent_name = @cron.trigger[5..-1].to_s.strip
        parent_j = @cron.user.crons.select do |user_cron|
          user_cron.name == parent_name
        end.first
        return parent_j
      else
        return nil
      end
    end

    def children
      @cron = self
      @cron.user.crons.select do |user_cron|
        parent_name = user_cron.trigger[5..-1].to_s.strip
        user_cron.trigger.strip[0..4].downcase == "after" and
          parent_name == @cron.name
      end
    end

    def is_due?
      @cron = self
      #working or inactive crons are not due
      if @cron.worker or @cron.active == false
        return false
      end

      #if cron contains paths in disabled APIs, not due
      unless @cron.transfer.paths.map{|p| p.disabled?}.compact.empty?
        return false
      end

      #once
      if @cron.trigger.strip.downcase=='once'
        #active and once means due
        return true
      end

      #depedencies
      if @cron.parent
        #if parent is not working and completed more recently than self, is due
        if !@cron.parent.is_working? and
          @cron.parent.completed_at and (j.completed_at.nil? or j.parent.completed_at > j.completed_at)
          return true
        else
          return false
        end
      end

      #time based
      last_comp_time = j.completed_at
      #check trigger; strip the "every" from the front if present, change dot to space
      trigger = j.trigger.strip.gsub("every","").gsub("."," ").strip
      number, unit, operator, mark = trigger.split(" ").map{|t_node| t_node.downcase}
      #operator is not used
      operator = nil
      #get time for time-based evaluations
      curr_time = Time.now.utc
      if ["hour","hours","day","days"].include?(unit)
        if mark
          last_mark_time = Time.at_marks_ago(number,unit,mark)
          if last_comp_time.nil? or last_comp_time < last_mark_time
            return true
          else
            return false
          end
        elsif last_comp_time.nil? or last_comp_time < (curr_time - number.to_i.send(unit))
          return true
        else
          return false
        end
      elsif unit == "day_of_month"
        if curr_time.day==number.to_i and (last_comp_time.nil? or last_comp_time.to_date != curr_time.to_date)
          if mark
            #check if it already ran today
            last_mark_time = Time.at_marks_ago(1,"day",mark)
            if last_comp_time < last_mark_time
              return true
            else
              return false
            end
          else
            return true
          end
        end
      else
        raise "Unknown #{unit.to_s} time unit"
      end
      #if nothing happens, return false
      return false
    end
  end
end
