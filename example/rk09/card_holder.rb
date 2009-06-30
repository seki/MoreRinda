require 'rinda/tuplespace'
require 'rinda/njet'

class CardHolder
  def initialize
    @ts = Rinda::TupleSpace.new
    @ts.write(['m_seki', 'http://d.hatena.ne.jp/m_seki', 'Hello, Again'])
  end

  def exchange(name, url, desc)
    @ts.write([name, url, desc])
    @ts.take([Rinda::Njet.new(name), nil, nil])
  end
end

DRb.start_service('druby://:56789', CardHolder.new)
puts DRb.uri
DRb.thread.join
