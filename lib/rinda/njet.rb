module Rinda
  class Njet
    def initialize(value)
      @value = value
    end
    
    def ===(other)
      @value != other
    end
  end
end
