module TDAmeritradeApi
  module Streamer

    # +create_streamer+ use this to create a connection to the TDA streaming server
    def create_streamer
      Streamer.new
    end

    class Streamer
      def run(&block)
        thread = Thread.new do
          25.times do |i|
            yield({the_data: 123, iteration: i})
            sleep 1
          end
        end
        thread.join
      end
    end
  end
end