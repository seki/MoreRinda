require 'thread'
require 'drb/drb'
require 'rinda/rinda'

class Agent
  def initialize(name, url, desc)
    @tuple = [name, url, desc]
    @inbox = Queue.new
    @renewer = Rinda::SimpleRenewer.new(15)
  end
  
  def pop
    @inbox.pop
  end
  
  def hello(name, url, desc)
    @inbox.push([name, url, desc])
    return @tuple
  end

  def meet(who)
    tuple = who.hello(*@tuple)
    @inbox.push(tuple)
  end
  
  def enter(place)
    place.write([:agent, @tuple[0], self], @renewer)
  end

  def broadcast(place)
    place.read_all([:agent, String, DRbObject]).each do |k, name, ro|
      next if name == @tuple[0]
      ro.meet(self) rescue nil
    end
  end
end

DRb.start_service
place = DRbObject.new_with_uri(ARGV.shift)

name = ARGV.shift || 'your_nick'
url = ARGV.shift || 'http://www.druby.org'
desc = ARGV.shift || 'no comment is good comment'

agent = Agent.new(name, url, desc)
agent.enter(place)
agent.broadcast(place)

while true
  p agent.pop
end


