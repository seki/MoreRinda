require 'drb/drb'
require 'rinda/rinda'

module Rinda
  module_function
  def rinda_eval(ts_org, result=[:died])
    r, w = IO.pipe(Encoding::BINARY)

    ts = DRbObject === ts_org ? ts_org : DRbObject.new(ts_org)
    pid = fork do
      r.close
      Thread.current['DRb'] = nil
      DRb.stop_service
      DRb.start_service
      tuple = yield(ts)
      Marshal.dump(tuple, w)
      exit(0)
    end
    Process.detach(pid)
    w.close

    Thread.new do
      begin
        result = Marshal.load(r)
      ensure
        ts_org.write(result)
        r.close
      end
    end
  end
end

if __FILE__ == $0
  require 'rinda/tuplespace'

  DRb.start_service()
  ts = Rinda::TupleSpace.new

  Process.setpgrp

  Thread.start(ts) do |place|
    p place.take([:died])
    Process.kill('KILL', 0)
    exit!(1)
  end

  (3..10).each do |it|
    Rinda::rinda_eval(ts) {|place|
      raise("hoge #{Process.pid} #{it}") if rand(10) == 0
      _, _, left = place.read([:fib, it-1, nil])
      exit!(1) if rand(10) == 0
      _, _, right = place.read([:fib, it-2, nil])
      [:fib, it, left + right]
    }
  end

  sleep(0.5)
  ts.write([:fib, 1, 1])
  ts.write([:fib, 2, 1])

  p ts.read([:fib, 10, nil])
end

