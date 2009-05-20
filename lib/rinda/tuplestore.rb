require 'rinda/tuplespace'
require 'monitor'

module Rinda
  class TupleStore
    def each; end
    def add(desc); end
    def delete(key); end
    def set_cancel(key); end
    def set_expires(key, value); end
  end

  class TupleStoreSimple < TupleStore
    include MonitorMixin

    def initialize
      super()
      @ser = 0
      @hash = {}
    end

    def each
      @hash.each do |k, v|
        next unless v
        next if v[:cancel]
        yield(k, v) if v
      end
    end
    
    def add(desc)
      synchronize do
        @ser += 1
        @hash[@ser] = desc
        return @ser
      end
    end
    
    def delete(key)
      @hash.delete(key)
    end

    def set_cancel(key)
      return unless @hash[key]
      @hash[key][:cancel] = true
    end

    def set_expires(key, value)
      return unless @hash[key]
      @hash[key][:expires] = value
    end
  end

  class TupleStoreLog < TupleStore
    include MonitorMixin

    def initialize(log_dir)
      super()
      @log_dir = log_dir
      @ser = 0
      @hash = {}
      restore
    end

    def each
      @hash.each do |k, v|
        next unless v
        next if v[:cancel]
        yield(k, v) if v
      end
    end
    
    def add(desc)
      synchronize do
        @ser += 1
        @hash[@ser] = desc
        File.open(File.join(@log_dir, @ser.to_s), 'wb') do |f|
          Marshal.dump(desc, f)
        end
        return @ser
      end
    end
    
    def delete(key)
      synchronize do
        @hash.delete(key)
        fname = File.join(@log_dir, key.to_s)
        File.rename(fname, fname + '_del')
        nil
      end
    end

    def set_attr(key, name, value)
      synchronize do
        return unless @hash[key]
        @hash[key][name] = value
        fname = File.join(@log_dir, key.to_s)
        File.open(fname + 'tmp', 'wb') do |f|
          Marshal.dump(@hash[key], f)
        end
        File.rename(fname + 'tmp', fname)
      end
    end

    def set_cancel(key)
      set_attr(key, :cancel, true)
    end

    def set_expires(key, value)
      set_attr(key, :expires, value)
    end

    def restore
      Dir.foreach(@log_dir) do |file|
        num = desc = nil
        if /([0-9]+)(_del)?/ =~ file
          num = $1.to_i
          @ser = num if @ser < num
          next if $2
          begin
            File.open(File.join(@log_dir, file), 'rb') do |f|
              desc = Marshal.load(f)
              @hash[num] = desc
            end
          rescue
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  uri = ARGV.shift || 'druby://localhost:12345'
  store = Rinda::TupleStoreLog.new('ts_log')
  DRb.start_service(uri, store)
  DRb.thread.join
end

