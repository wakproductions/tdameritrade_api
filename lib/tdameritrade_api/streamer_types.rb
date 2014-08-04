module TDAmeritradeApi
  module StreamerTypes
    SERVICE_ID={
        quote: "1",
        timesale: "5",
        response: "10",
        option: "18",
        actives_nyse: "23",
        actives_nasdaq: "25",
        actives_otcbb: "26",
        actives_options: "35",
        news: "27",
        news_history: "28",
        adap_nasdaq: "62",
        nyse_book: "81",
        nyse_chart: "82",
        nasdaq_chart: "83",
        opra_book: "84",
        index_chart: "85",
        total_view: "87",
        acct_activity: "90",
        chart: "91",
        streamer_server: "100"
    }

    LEVEL1_COLUMN_NUMBER={
        symbol: 0,
        bid: 1,
        ask: 2,
        last: 3,
        bidsize: 4,
        asksize: 5,
        bidid: 6,
        askid: 7,
        volume: 8,
        lastsize: 9,
        tradetime: 10,
        quotetime: 11,
        high: 12,
        low: 13,
        tick: 14,
        close: 15,
        exchange: 16,
        marginable: 17,
        shortable: 18,
        quotedate: 22,
        tradedate: 23,
        volatility: 24,
        description: 25,
        trade_id: 26,
        digits: 27,
        open: 28,
        change: 29,
        week_high_52: 30,
        week_low_52: 31,
        p_e_ratio: 32,
        dividend_amt: 33,
        dividend_yield: 34,
        nav: 37,
        fund: 38,
        exchange_name: 39,
        dividend_date: 40,
        last_market_hours: 41,
        lastsize_market_hours: 42,
        tradedate_market_hours: 43,
        tradetime_market_hours: 44,
        change_market_hours: 45,
        is_regular_market_quote: 46,
        is_regular_market_trade: 47
    }

    LEVEL1_COLUMN_TYPE={
        symbol: :string,
        bid: :float,
        ask: :float,
        last: :float,
        bidsize: :int,
        asksize: :int,
        bidid: :char,
        askid: :char,
        volume: :long,
        lastsize: :int,
        tradetime: :int,
        quotetime: :int,
        high: :float,
        low: :float,
        tick: :char,
        close: :float,
        exchange: :char,
        marginable: :boolean,
        shortable: :boolean,
        quotedate: :int,
        tradedate: :int,
        volatility: :float,
        description: :string,
        trade_id: :char,
        digits: :int,
        open: :float,
        change: :float,
        week_high_52: :float,
        week_low_52: :float,
        p_e_ratio: :float,
        dividend_amt: :float,
        dividend_yield: :float,
        nav: :float,
        fund: :float,
        exchange_name: :string,
        dividend_date: :string,
        last_market_hours: :float,
        lastsize_market_hours: :int,
        tradedate_market_hours: :int,
        tradetime_market_hours: :int,
        change_market_hours: :float,
        is_regular_market_quote: :boolean,
        is_regular_market_trade: :boolean
    }

    STREAM_DATA_TYPE=[:heartbeat, :snapshot, :stream_data]
    class StreamData
      attr_accessor :stream_data_type, :timestamp_indicator, :timestamp, :service_id, :message, :message_length, :columns

      def initialize(stream_data_type)
        @stream_data_type=stream_data_type
      end

      def service_type
        SERVICE_ID.key(service_id)
      end
    end
  end
end