require 'drb/drb'
require 'rinda/tuplespace'

module Rinda
  class TupleSpace
    attr_reader :bag, :read_waiter, :take_waiter, :notify_waiter

    def report
      synchronize do
        TupleSpaceReport.new(self)
      end
    end
  end

  class TupleBag
    include Enumerable
    def each(&blk)
      each_entry(&blk)
    end
  end

  class WaitTemplateEntry
    attr_reader :cond
  end

  class TupleSpaceReport
    def initialize(ts)
      @tuple = ts.bag.collect {|t| t.value}
      @reader = ts.read_waiter.collect {|t| [t.value, waiters(t)]}
      @taker = ts.take_waiter.collect {|t| [t.value, waiters(t)]}
    end
    attr_reader :tuple, :reader, :taker

    def waiters(tuple)
      tuple.cond.instance_variable_get(:@waiters).collect do |th|
        [th, (th[:DRb]['client'].stream.peeraddr rescue nil)]
      end[0]
    end
  end
end

if __FILE__ == $0
  require 'pp'

  def report(ts)
    pp ts.report
  end
  
  ts = Rinda::TupleSpace.new
  DRb.start_service(nil, ts)
  p DRb.uri
  
  t1 = Thread.new { p ts.take([:hello, :world]) }
  t2 = Thread.new { p ts.read([:hello, :nil]) }
  sleep 1
  report(ts)
  ts.write([:hello, :world])
  report(ts)
  sleep 1
  report(ts)
  gets
  report(ts)
end
