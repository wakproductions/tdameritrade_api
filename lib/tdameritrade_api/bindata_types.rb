require 'bindata'

module TDAmeritradeApi
  module BinDataTypes
    class PriceHistoryHeader < BinData::Record
      int32be    :symbol_count
    end

    class PriceHistorySymbolData < BinData::Record
      int16be    :symbol_length
      string     :symbol, :read_length=>:symbol_length
      int8be     :error_code
      int16be    :error_length, :onlyif => :has_error?
      string     :error_text, :onlyif => :has_error?, :length=>:error_length
      int32be    :bar_count

      def has_error?
        error_code != 0
      end
    end

    # IMPORTANT NOTE (4/23/15):
    # When using currency in Ruby, it is recommended to use BigDecimal instead of
    # float types due to rounding errors with the float type. I have discovered that in
    # Ruby 2.2 you may have issues with ActiveRecord if your database stores these values
    # as a decimal type because this gem outputs the close, high, low, open, and volume
    # values in float type. The fix is either to have rounding through a precision value
    # in your database field or to typecast the output of TDAmeritradeAPI gem to BigDecimal.
    # I currently have no plans to change the code here since a 4-byte float is what is
    # used by TD Ameritrade's system and I want to keep the output of this gem consistent
    # with the specs used by TDA.
    class PriceHistoryBarRaw < BinData::Record
      float_be    :close   # may have to round this on a 64 bit system
      float_be    :high    # may have to round this on a 64 bit system
      float_be    :low     # may have to round this on a 64 bit system
      float_be    :open    # may have to round this on a 64 bit system
      float_be    :volume  # in 100s
      int64be     :timestampint # number of milliseconds - needs to be converted to seconds for Ruby
    end

  end
end