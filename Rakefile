require "bundler/gem_tasks"
require 'tdameritrade_api'

task :test_equity_order do
  c = TDAmeritradeApi::Client.new
  c.login

  my_trade = {:quantity => 300, 
  :action => :buy, 
  :ordtype => :limit, 
  :price => 1, 
  :clientorderid => 20150925140834,
  :expire => :day}
  c.submit_order('TNA', my_trade)
end

task :test_conditional_order do
  c = TDAmeritradeApi::Client.new
  c.login

  my_trade = {
    :clientorderid => 20150925140834,
    :ordticket => :otoca,
    :totlegs => 3,
    
    :quantity1 => 300, 
    :action1 => :buy, 
    :ordtype1 => :limit, 
    :price1 => 2, 
    :expire1 => :day,
    
    :quantity2 => 300, 
    :action2 => :sell, 
    :ordtype2 => :limit, 
    :price2 => 3, 
    :expire2 => :day,
    
    :quantity3 => 300, 
    :action3 => :sell, 
    :ordtype3 => :stop_market, 
    :price3 => 1, 
    :expire3 => :day,
    
    }
  c.submit_order('TNA', my_trade, true)
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

task :test_bp do
  c = TDAmeritradeApi::Client.new
  c.login

  options = {:type => 'p', 
  :suppressquote => 'true'}
  bp = c.get_balances_and_positions(options)
  p bp
end
