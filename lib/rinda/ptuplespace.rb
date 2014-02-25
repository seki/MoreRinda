require 'rinda/tuplespace'
require 'rinda/tuplestore'
require 'singleton'
require 'weakref'

module Rinda
  class PTupleEntryCache
    include Singleton

    def initialize
      @cache = {}
    end

    def [](serial)
      ref = @cache[serial]
      return nil unless ref
      it = ref.__getobj__
      @cache.delete(serial) unless it
      return it
    end

    def register(tuple)
      @cache[tuple.serial] = WeakRef.new(tuple)
    end
  end

  class PTupleEntry < TupleEntry
    def self.new_with_desc(key, desc)
      store = Rinda.tuple_store
      it = allocate
      it.instance_variable_set('@store', store)
      it.instance_variable_set('@serial', key)
      it.instance_variable_set('@tuple', desc[:tuple])
      it.instance_variable_set('@expires', desc[:expires])
      it.instance_variable_set('@cancel', desc[:cancel])
      it.instance_variable_set('@renewer', desc[:renewer])
      PTupleEntryCache.instance.register(it)
      it
    end

    def to_store
      { :tuple => @tuple,
        :expires => @expires,
        :cancel => @cancel,
        :renewer => @renewer }
    end

    def initialize(*arg)
      super(*arg)
      @store = Rinda.tuple_store
      @serial = @store.add(to_store)
      PTupleEntryCache.instance.register(self)
    end
    attr_reader :serial

    def cancel
      super
      @store.set_cancel(@serial)
    end

    def delete
      @store.delete(@serial)
    end

    def expires=(it)
      super(it)
      @store.set_expires(@serial, it)
    end

    def renew(it)
      old = @expires
      super(it)
      return unless @store
      @store.set_expires(@serial, @expires) unless old == @expires
    end
  end

  class PTupleSpace < TupleSpace
    def initialize(*arg)
      super(*arg)
      @bag = PTupleBag.new
    end

    def create_entry(tuple, sec)
      PTupleEntry.new(tuple, sec)
    end

    def restore
      @bag.restore
    end
  end

  class PTupleBag < TupleBag
    def initialize(*var)
      super(*var)
    end
    attr_reader :store

    def delete(tuple)
      it = super(tuple)
      return nil unless it
      tuple.delete
      it
    end

    def restore
      Rinda.tuple_store.each do |k, v|
        tuple = PTupleEntry.new_with_desc(k, v)
        if tuple.expired?
          tuple.delete
        else
          push(tuple)
        end
        nil
      end
    end
  end

  class TupleStoreIdConv < DRb::DRbIdConv
    def tuple_store?(ref)
      return false unless ref.kind_of?(Array)
      return false unless ref[0] == :TupleStoreId
      return true
    end

    def to_obj(ref)
      if tuple_store?(ref)
        PTupleEntryCache.instance[ref[1]]
      else
        super(ref)
      end
    end

    def to_id(obj)
      if obj.class == PTupleEntry
        [:TupleStoreId, obj.serial]
      else
        super(obj)
      end
    end
  end

  def setup_tuple_store(store)
    raise "tuple_store was assinged" if @tuple_store
    @tuple_store = store
  end
  module_function :setup_tuple_store

  def tuple_store
    @tuple_store
  end
  module_function :tuple_store
end

if __FILE__ == $0
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
end
