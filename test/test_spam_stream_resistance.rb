require 'minitest_helper'

#rake test TEST=test/test_spam_stream_resistance.rb
class TestSpamStreamResistance < Minitest::Test
  def setup
  	#default settings { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} }
    #Flush the Lua scripts cache 
    @redis = Redis.new({host: 'localhost', port: 6379, db: 10})
    @redis.script "FLUSH"
    @spam_stream_resistance = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
    
  end

  def test_object_should_has_three_standart_filters
    #[filter_1, filter_2, filter_3]
    filters_list = @spam_stream_resistance.filters_list

    assert filters_list.include?("filter_1"), "Filter 1 does not exist"
    assert filters_list.include?("filter_2"), "Filter 2 does not exist"
    assert filters_list.include?("filter_3"), "Filter 3 does not exist"
  end

  def test_filter_1
    #key - email address or something else. (string type)
    #increas_time - seconds
    # Count of requests is stored in a key
    # Filter checks if count of requests in a key (email address) less than can be in a lifetime of the key
    # If count of requests more than can be, the filter will increase the lifetime of the key (email address) on increas_time
    #but will not increase count of requests that associated with key
    #but will not increase count of requests in key
    # filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)
    #If count of requests more than can be, the filter_1 return true else false
    #If the filter_1 return empty string, it might be something wrong

    key = "user@mail.com"
    max_count_of_request = 10
    lifetime_of_the_key  = 20
    increas_time         = 5

    #if spam return 1 else return nil

    @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)

  end
end
