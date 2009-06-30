require 'rinda/tuplespace'
require 'rinda/inspect'
require 'rinda/njet'

ts = Rinda::TupleSpace.new(15)
DRb.start_service('druby://:56788', ts)

while true
  puts
  puts DRb.uri
  ts.report.tuple.each do |t|
    p [t[0], t[1], t[2].__drburi]
  end
  sleep 10
end


