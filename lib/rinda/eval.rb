require 'drb/drb'
require 'rinda/rinda'

module Rinda
  module_function
  def rinda_eval(ts)
    Thread.pass # FIXME
    ts = DRbObject.new(ts) unless DRbObject === ts
    pid = fork do
      Thread.current['DRb'] = nil
      DRb.stop_service
      DRb.start_service
      place = TupleSpaceProxy.new(ts)
      tuple = yield(place)
      place.write(tuple) rescue nil
    end
    Process.detach(pid)
  end
end
