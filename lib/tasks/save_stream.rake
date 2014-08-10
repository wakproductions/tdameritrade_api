namespace :tdameritrade_api do

  # This is a very barebones utility. I can add more configuration features to this if anyone finds it useful.
  desc "Saves a TD Ameritrade Level 1 stream to file for later backtesting"
  task :save_stream => :environment do
    i = 0
    file_num = 1
    request_fields = [:volume, :last, :bid, :symbol, :ask, :quotetime, :high, :low, :close, :tradetime, :tick]
    symbols = watchlist
    file_name =

    while true
      begin
        file_num += 1 while File.exists? File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_archives', new_mock_data_file_name(file_num))
        streamer.output_file = File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_archives', new_mock_data_file_name(file_num)) if use_mock_data_file
        streamer.run(symbols: symbols, request_fields: request_fields) do |data|
          data.convert_time_columns
          case data.stream_data_type
            when :heartbeat
              pout "Heartbeat: #{data.timestamp}"
            when :snapshot
              if data.service_id == "100"
                pout "Snapshot SID-#{data.service_id}: #{data.columns[:description]}"
              else
                pout "Snapshot: #{data}"
              end
            when :stream_data
              pout "#{i} Stream: #{data.columns}"
              i += 1
            else
              pout "Unknown type of data: #{data}"
          end
        end
      rescue Exception => e
        # This idiom of a rescue block you can use to reset the connection if it drops,
        # which can happen easily during a fast market.
        if e.class == Errno::ECONNRESET
          puts "Connection reset, reconnecting..."
        else
          raise e
        end
      end
    end

  end
end