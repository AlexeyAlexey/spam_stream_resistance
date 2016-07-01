$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'spam_stream_resistance'
require 'spam_stream_resistance/redis_scripts'



require 'minitest/autorun'

require  "redis"  
require  "connection_pool"
require  "byebug"

require 'benchmark'
