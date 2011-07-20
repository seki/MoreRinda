require 'thread'

class ActorsOffice
  def initialize(actor)
    @queue = Queue.new
    @thread = Thread.new(actor) do
      catch(actor) do
        while true
          msg, arg, blk = @queue.pop
          actor.__send__(msg, *arg, &blk)
        end
      end
    end
  end
  def __thread__; @thread; end

  def method_missing(m, *a, &b)
    @queue.push([m, a, b])
  end
end

class BarberShop
  def initialize
    @chairs = []
  end

  def barber=(barber)
    @barber = barber
  end

  def new_customer(name)
    puts "<< arriving #{name}"
    if (@chairs.size >= 3)
      puts "** sorry, no room for #{name} **"
    else
      @chairs << name
      @barber.wake_up
    end
  end

  def customer_leaves
    barber_check
  end

  def barber_check
    @barber.customer(@chairs.shift) unless @chairs.empty?
  end

  def quit
    puts 'quit'
    throw(self)
  end
end

class Barber
  def initialize(shop)
    @shop = shop
  end

  def cut(name)
    puts "cutting #{name}."
    sleep(rand(5))
    puts "finishing cutting #{name}.>>"
    @shop.customer_leaves
  end

  def wake_up
    @shop.barber_check
  end

  def customer(name)
    cut(name)
    @shop.barber_check
  end
end

shop = ActorsOffice.new(BarberShop.new)
shop.barber = ActorsOffice.new(Barber.new(shop))

%w(jack john henry tom bob m_seki makoto).each do |name|
  shop.new_customer(name)
  sleep(1)
end

gets
