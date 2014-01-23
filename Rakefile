require "bundler/gem_tasks"
require 'tdameritrade_api'

task :perform_action do
  c = TDAmeritradeApi::Client.new
  #c.login
  c.session_id="87DF7AFCF5D60DB9A1AC1B1B74248ED2.TOGKE6VP9aE8jmnkLXaVXg"
  prices = c.get_minute_price_history('CAT',150)
  of = open(File.join(Dir.getwd, "output.txt"), "w")
  prices.each do |bar|
    of.write "#{bar[:open]} #{bar[:high]} #{bar[:low]} #{bar[:close]} #{bar[:timestamp]}\n"
  end
  of.close
end
