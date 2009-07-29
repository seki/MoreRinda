require 'rinda/tuplestore'
require 'tokyocabinet'

module Rinda
  class TokyoStore < TupleStore
    class BDBError < RuntimeError
      def initialize(bdb)
        super(bdb.errmsg(bdb.ecode))
      end
    end

    class BDB < TokyoCabinet::BDB
      def exception
        BDBError.new(self)
      end
      
      def cursor
        TokyoCabinet::BDBCUR.new(self)
      end
      
      def self.call_or_die(*ary)
        file, lineno = __FILE__, __LINE__
        if /^(.+?):(¥d+)(?::in `(.*)')?/ =~ caller(1)[0]
          file = $1
          lineno = $2.to_i
        end
        ary.each do |sym|
          module_eval("def #{sym}(*arg); super || raise(self); end",
                      file, lineno)
        end
      end
      
      call_or_die :open, :close
      call_or_die :tranbegin, :tranabort, :trancommit
      call_or_die :vanish
    end

    include MonitorMixin
    def initialize(name)
      super()
      @name = name
      @bdb = BDB.new
      writer {}
      @my_nil = Marshal.dump(nil)
    end

    def transaction(mode)
      synchronize do
        begin
          @bdb.open(@name, mode)
          return yield
        ensure
          @bdb.close
        end
      end
    end

    def reader(&block)
      transaction(BDB::OREADER, &block)
    end

    def writer(&block)
      transaction(BDB::OWRITER | BDB::OCREAT, &block)
    end

    def load(val)
      val ? Marshal.load(val) : nil
    end

    def each
      reader do
        cursor = @bdb.cursor
        cursor.jump('t.')
        while cursor.key
          break unless /^t\.(\w+)/ =~ cursor.key
          key = $1
          desc = Hash.new
          desc[:tuple] = load(cursor.val)
          cursor.next
          next unless desc[:tuple]
          next if @bdb["c.#{key}"]
          desc[:renewer] = load(@bdb["r.#{key}"])
          desc[:expires] = load(@bdb["e.#{key}"])
          yield(key, desc)
        end
      end
    end

    def add(desc)
      writer do
        ser = (@bdb['ser'] || 0).to_i + 1
        @bdb['ser'] = ser
        key = ser.to_s(36)
        @bdb["t.#{key}"] = Marshal.dump(desc[:tuple])
        @bdb["r.#{key}"] = Marshal.dump(desc[:renewer])
        @bdb["e.#{key}"] = Marshal.dump(desc[:epires])
        @bdb["c.#{key}"] = 't' if desc[:cancel]
        return key
      end
    end
    
    def delete(key)
      writer do
        @bdb.out("t.#{key}")
        @bdb.out("r.#{key}")
        @bdb.out("e.#{key}")
        @bdb.out("c.#{key}")
      end
    end

    def set_cancel(key)
      writer do
        @bdb["c.#{key}"] = 't'
      end
    end

    def set_expires(key, value)
      writer do
        @bdb["e.#{key}"] = Marshal.dump(value)
      end
    end
  end
end
