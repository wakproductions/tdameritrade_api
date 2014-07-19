# TDAmeritradeApi (alpha)

This is a gem for connecting to the TD Ameritrade API.

## Installation

Add this line to your application's Gemfile:

    gem 'tdameritrade_api', :git=>'https://github.com/wakproductions/tdameritrade_api.git'

## Important Note

This is in the very early stages of development. It has very limited functionality in comparison to the entirety
of the API. See the /vendor/docs folder for more details on the overall API.

## Setup

To use this, you need to have 3 environment variables set:
    TDAMERITRADE_SOURCE_KEY - this is given to you by TD Ameritrade
    TDAMERITRADE_USER_ID    - your username to connect to TD Ameritrade
    TDAMERITRADE_PASSWORD   - your account password for TD Ameritrade


## Basic Usage

To connect to the TD Ameritrade API using this gem, create an instance of TDAmeritrade::Client and then
call the methods you need.

    c = TDAmeritrade::Client.new
    c.login
    #=> true

    c.get_price_history('MSFT', intervaltype: :minute, intervalduration: 15, periodtype: :day, period: 10)
    => [{:open=>41.75, :high=>41.87, :low=>41.71, :close=>41.85, :volume=>17955.3, :timestamp=>2014-07-07
       09:30:00 -0400, :interval=>:day}, {:open=>41.85, :high=>41.92, :low=>41.84, :close=>41.9, :volume=>7380.78,
       :timestamp=>2014-07-07 09:45:00 -0400, :interval=>:day},...  a long hash array of the price candles]

## Currently Supported Methods

The only API features really supported right now are the ability to capture real time quotes and
price history for a given security
#login
#get_price_history
#get_quote
#get_daily_price_history
#get_minute_price_history
