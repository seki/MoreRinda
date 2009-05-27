require 'rinda/tuplespace'
require 'rinda/njet'
require 'test/unit'

class NjetTest < Test::Unit::TestCase
  include Rinda
  def test_match
    ts = Rinda::TupleSpace.new
    assert_equal([], ts.read_all([Njet.new(10)]))
    ts.write([10])
    assert_equal([], ts.read_all([Njet.new(10)]))
    ts.write([11])
    assert_equal([[11]], ts.read_all([Njet.new(10)]))
    ts.write([12])
    assert_equal([[11], [12]], ts.read_all([Njet.new(10)]).sort)
  end

  def test_wait_for_change
    ts = Rinda::TupleSpace.new

    ts.write([:state, 1])
    _, last_state = ts.read([:state, nil])

    assert_raise(Rinda::RequestExpiredError) do
      ts.read([:state, Njet.new(last_state)], 0)
    end

    tuple = ts.take([:state, nil])
    tuple[1] += 1
    ts.write(tuple)

    assert_equal([:state, 2], ts.read([:state, Njet.new(last_state)], 0))
  end
end
