require 'rinda/tuplespace'
require 'rinda/eval'

class BarberShop
  def initialize(ts)
    @ts = ts
    @waiting = []
  end

  def start
    @ts.write([:shop, @waiting])
    while true
      addr, msg, arg = @ts.take([:shop, nil, nil])
      case msg
      when :new_customer
        name = arg
        puts "<< arriving #{name}"
        if (@waiting.size >= 3)
          puts "** sorry, no room for #{name} **"
        else
          @waiting << name
          @ts.write([:barber, :wake_up, nil])
        end
      when :customer_leaves
        puts "leaving #{@waiting.shift}>>"
        @ts.write([:barber, :customer, @waiting[0]])
      when :barber_check
        @ts.write([:barber, :customer, @waiting[0]])
      when :quit
        return
      end
      @ts.take([:shop, nil])
      @ts.write([:shop, @waiting])
    end
  end
end

class Barber
  def initialize(ts)
    @ts = ts
  end

  def start
    @ts.write([:barber, 'sleep'])
    while true
      addr, msg, arg = @ts.take([:barber, nil, nil])
      case msg
      when :wake_up
        @ts.take([:barber, nil])
        @ts.write([:barber, 'wake up'])
        @ts.write([:shop, :barber_check, nil])
      when :customer
        if arg
          cut(arg)
          @ts.write([:shop, :customer_leaves, nil])
        else
          puts "                     sleeping"
          @ts.take([:barber, nil])
          @ts.write([:barber, 'sleep'])
        end
      when :quit
        return
      end
    end
  end

  def cut(name)
    puts "                     cutting #{name}."
    rand(5).times do
      puts "                        cutting..."
      sleep(1)
    end
    puts "                     finishing cutting #{name}."
  end
end

place = Rinda::TupleSpace.new
DRb.start_service('druby://localhost:0')

Rinda::rinda_eval(place) do |ts|
  BarberShop.new(ts).start
  [:shop]
end

Rinda::rinda_eval(place) do |ts|
  Barber.new(ts).start
  [:barber]
end

%w(jack john henry tom bob m_seki makoto).each do |name|
  place.write([:shop, :new_customer, name])
  sleep(2)
end

p place.read([:shop, []])
p place.read([:barber, 'sleep'])

place.write([:shop, :quit, nil])
place.write([:barber, :quit, nil])

p place.take([:shop])
p place.take([:barber])
