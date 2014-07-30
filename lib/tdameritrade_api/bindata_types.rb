require 'bindata'

module TDAmeritradeApi
  module BinDataTypes
    class PriceHistoryHeader < BinData::Record
      int32be    :symbol_count
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