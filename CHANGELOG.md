### v1.2.1

Removed accidental binding.pry statements

### v1.2.0

Added feature to view, create, and edit watchlists available in ThinkOrSwim.

### v1.1.1

Added missing fields to the output of #get_quote, the real-time quote retrieval method. Now includes
error (if any), description, year high/low, exchange, asset type.

### v1.1.0

Added ability to retrieve account balances and positions.

### v1.0.20150422 Known Issues

steamer_spec.rb has a flickering test in that it fails outside of the US/Eastern time zone. The problem
is in the TDAmeritradeApi::StreamerTypes::StreamData.convert_time_columns in converting the time. The
TD Ameritrade system gives trade_time and quote_time in number of seconds since midnight Eastern Time.
Converting this to a DateTime object requires doing DateTime.today (or whichever day) converted
to a Time object + the value in trade_time or quote_time. The problem is that when you build a DateTime
object and convert it to Time, Ruby uses the local time zone. To fix this you need to convert the input
of convert_time_columns(day) into an Eastern Time Zone midnight value. This will be fixed soon but
for now I am disabling that particular validation in the test.