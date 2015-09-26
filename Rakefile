require "bundler/gem_tasks"
require 'tdameritrade_api'

task :test_equity_order do
  c = TDAmeritradeApi::Client.new
  c.login

  my_trade = {:quantity => 100, 
  :action => :buy, 
  :ordtype => :limit, 
  :price => 1, 
  :clientorderid => 20150925140834,
  :expire => :day}
  c.submit_order('IBM', my_trade)
end

task :perform_action do
  c = TDAmeritradeApi::Client.new
  c.login
  #c.session_id="128459556EEA989391FBAAA5E2BF8EB4.cOr5v8xckaAXQxWmG7bn2g"
  #prices = c.get_minute_price_history('GM',10)
  prices = c.get_daily_price_history('FOX', '20140105', '20140123')
  of = open(File.join(Dir.getwd, "output.txt"), "w")
  prices.each do |bar|
    of.write "#{bar[:open]} #{bar[:high]} #{bar[:low]} #{bar[:close]} #{bar[:timestamp]}\n"
  end
  of.close
end
