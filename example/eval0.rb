require 'rinda/tuplespace'
require 'rinda/eval'

place = Rinda::TupleSpace.new
DRb.start_service

10.times do |n|
  Rinda::rinda_eval(place) do |ts|
    [:sqrt, n, Math.sqrt(n)]
  end
end

10.times do |n|
  p ts.read([:sqrt, n, nil])
end
