# TD Ameritrade API gem for Ruby

[![Build Status](https://travis-ci.org/wakproductions/tdameritrade_api.svg?branch=master)](https://travis-ci.org/wakproductions/tdameritrade_api) [![Code Climate](https://codeclimate.com/github/wakproductions/tdameritrade_api/badges/gpa.svg)](https://codeclimate.com/github/wakproductions/tdameritrade_api)

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

To connect to the TD Ameritrade API using this gem, create an instance of TDAmeritradeApi::Client and then
call the methods you need.

    c = TDAmeritradeApi::Client.new
    c.login
    #=> true

    c.get_price_history('MSFT', intervaltype: :minute, intervalduration: 15, periodtype: :day, period: 10)
    #=> [{:open=>41.75, :high=>41.87, :low=>41.71, :close=>41.85, :volume=>17955.3, :timestamp=>2014-07-07
       09:30:00 -0400, :interval=>:day}, {:open=>41.85, :high=>41.92, :low=>41.84, :close=>41.9,
       :volume=>7380.78, :timestamp=>2014-07-07 09:45:00 -0400, :interval=>:day},...  a long hash array of
       the price candles]

## Currently Supported Methods

The only API features really supported right now are the ability to capture real time quotes,
price history, and streaming of Level 1 quotes.

    login
    get_price_history   # retrieves historical data
    get_quote           # gets realtime snapshots of quotes

## Streaming

    c = TDAmeritradeApi::Client.new
    c.login
    streamer = c.create_streamer
    streamer.run(symbols: symbols, request_fields: [:volume, :last, :symbol, :quotetime, :tradetime]) do |data|
       # Process the stream data here - this block gets called for every new chunk of data received from TDA
       # See what's in the data hash to get the requested information streaming in about the stock
    end

The streamer also has the ability to read and write from a hard disk file for testing:

    # This output_file attribute will cause the stream to be saved into a file as its being processed
    streamer.output_file = '/Users/wkotzan/Development/gem-development/tda_stream_daemon/cache/stream20150205.binary'

    # Run this code to read a stream from a presaved file
    input_file = '~/stream20150213-should-have-WUBA-1010am.binary'
    streamer = TDAmeritradeApi::Streamer::Streamer.new(read_from_file: input_file)

## Contributions

If you would like to make a contribution, please submit a pull request to the original branch. Feel free to email me Winston Kotzan
at wak@wakproductions.com with any feature requests, bug reports, or feedback.


## Release Notes

### Version 1.1 Alpha
- Adding balances, positions and trade modules
