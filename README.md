# TDAmeritradeApi (alpha)

This is a gem for connecting to the TD Ameritrade API.

## Installation

Add this line to your application's Gemfile:

    gem 'tdameritrade_api', :git=>'https://github.com/wakproductions/tdameritrade_api.git'

## Important Note

This is in the very early stages of development and intended for Winston's personal use. It has very limited
functionality in comparison to the entirety of the API. See the /vendor/docs folder for more details on the
overall API.

## Setup

To use this, you need to have 3 environment variables set:
    TDAMERITRADE_SOURCE_KEY - this is given to you by TD Ameritrade
    TDAMERITRADE_USER_ID    - your username to connect to TD Ameritrade
    TDAMERITRADE_PASSWORD   - your account password for TD Ameritrade


## Methods - look it up in the code!

TDAmeritrade::Client
login
get_daily_price_history
get_minute_price_history