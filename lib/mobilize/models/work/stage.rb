module Mobilize
  #a stage defines a set of tasks that must be completed before the next stage can begin
  class Stage
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Status
    field :job_id, type: String
    field :order,  type: Fixnum
    field :name,   type: String, default:->{"stage" + ("%02d" % order)}
    field :call,   type: String #read, write, or run
    field :_id,    type: String, default:->{"#{job_id}/#{name}"}
    belongs_to :job
    has_many :tasks
  end
end
