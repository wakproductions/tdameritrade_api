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

    STREAM_DATA_TYPE=[:heartbeat, :snapshot, :stream_data]
    class StreamData
      attr_accessor :stream_data_type, :timestamp_indicator, :timestamp, :service_id, :message

      def initialize(stream_data_type)
        @stream_data_type=stream_data_type
      end

      def service_type
        SERVICE_ID.key(service_id)
      end
    end
  end
end