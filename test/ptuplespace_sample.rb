require 'rinda/ptuplespace'

#  store = DRbObject.new_with_uri('druby://localhost:12345')
store = Rinda::TupleStoreLog.new('ts_log')
Rinda::setup_tuple_store(store)
  
DRb.install_id_conv(Rinda::TupleStoreIdConv.new)
ts = Rinda::PTupleSpace.new
DRb.start_service('druby://localhost:23456', ts)
ts.restore
#  sleep

ts.write(['Hello', 'World'])
p ts.read_all(['Hello', nil])
p ts.take(['Hello', nil])

x = ts.write(['Hello', 'cancel'], 2)
p ts.read_all(['Hello', nil])
ref = DRbObject.new(x)
ref.cancel
p ts.read_all(['Hello', nil])
x = ts.write(['Hello', 'World'])

p DRbObject.new(x)

File.open('test.dat', 'wb') do |x|
  Marshal.dump(store, x)
end 
