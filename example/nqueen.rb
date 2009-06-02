require 'rinda/tuplespace'
require 'rinda/eval'

module NQueen
  module_function
  def concat(board, row)
    board.each_with_index do |v, col|
      check = (v - row).abs
      return nil if check == 0
      return nil if check == board.size - col
    end
    board + [row]
  end

  def nq(size, board=[])
    found = 0
    size.times do |row|
      fwd = concat(board, row)
      next unless fwd
      return 1 if fwd.size == size
      found += nq(size, fwd)
    end
    found
  end

  def nq2(size, r1, r2)
    board = concat([r1], r2)
    return 0 unless board
    nq(size, board)
  end
end

def invoke_engine(rinda, num)
  num.times do
    Rinda::rinda_eval(rinda) do |ts|
      begin
        while true
          sym, size, r1, r2 = ts.take([:nq, Integer, Integer, Integer])
          ts.write([:nq_ans, size, r1, r2, NQueen.nq2(size, r1, r2)])
        end
      rescue
      end
      [:nq_engine]
    end
  end
end

def write_q(rinda, size)
  size.times do |r1|
    size.times do |r2|
      rinda.write([:nq, size, r1, r2])
    end
  end
end

def take_a(rinda, size)
  found = 0
  size.times do |r1|
    size.times do |r2|
      tuple = rinda.take([:nq_ans, size, r1, r2, nil])
      found += tuple[4]
    end
  end
  found
end

def resolve(rinda, size)
  write_q(rinda, size)
  take_a(rinda, size)
end


DRb.start_service
rinda = Rinda::TupleSpace.new
size = (ARGV.shift || '5').to_i

invoke_engine(rinda, 4)
puts resolve(rinda, size)
