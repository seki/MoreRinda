require 'rinda/tuplespace'
require 'rinda/eval'

class Phil
  def initialize(ts, n, num)
    @ts = ts
    @right = n
    @left = (n + 1) % num
  end

  def run
    while running?
      do_it(:think)
      @ts.take([:room_ticket])
      @ts.take([:chopstick, @right])
      @ts.take([:chopstick, @left])
      do_it(:eat)
      @ts.write([:chopstick, @right])
      @ts.write([:chopstick, @left])
      @ts.write([:room_ticket])
    end
  end
  
  def running?
    @ts.read_all([:done]).size == 0
  end
  
  def do_it(symbol)
    sleep(rand)
    @ts.write(p [symbol, @right])
  end
end

def main
  place = Rinda::TupleSpace.new
  DRb.start_service

  num = 10
  num.times do |n|
    place.write([:chopstick, n])
    Rinda::rinda_eval(place) do |ts|
      phil = Phil.new(ts, n, num)
      phil.run
      [:phil, n]
    end
  end

  (num - 1).times do |n|
  place.write([:room_ticket])
  end
  
  sleep(10)
  
  place.write([:done])

  num.times do |n|
    place.take([:phil, n])
    p [n, place.read_all([:think, n]).size]
  end
end

main
