require 'minitest_helper'

#rake test TEST=test/test_spam_stream_resistance.rb
#rake test TEST=test/test_spam_stream_resistance.rb TESTOPTS="--name=test_should_add_new_filter -v"
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

  def test_filter_1_must_be_spam
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
    lifetime_of_the_key  = 7
    increas_time         = 5

    #if spam return true else return false
    
    @redis.get "filter_1:#{key}"
    
    measure_the_time = Benchmark.measure do 
      10.times do |i|
        @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)
      end
    end

    assert @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time) and measure_the_time.real < lifetime_of_the_key

  end

  def test_filter_1_must_not_be_spam_time_expired
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
    lifetime_of_the_key  = 7
    increas_time         = 5

    #if spam return 1 else return nil
    
    @redis.del "filter_1:#{key}"
    
    measure_the_time = Benchmark.measure do 
      10.times do |i|
        @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)
      end
    end
    
    time_sleep = lifetime_of_the_key + increas_time
    
    sleep (time_sleep)

    assert (@spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time) == false)

  end

  def test_key_exist_in_filter
    key = "user@mail.com"
    max_count_of_request = 10
    lifetime_of_the_key  = 60
    increas_time         = 5

    filter_name = "filter_1"
    
    @redis.del "#{filter_name}:#{key}"

    @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)

    assert @spam_stream_resistance.filter_key_exists?(filter_name, key)
  end

  def test_delete_key_from_filter
    key = "user@mail.com"
    filter_name = "filter_1"

    max_count_of_request = 10
    lifetime_of_the_key  = 60
    increas_time         = 5
    
    @redis.del "#{filter_name}:#{key}"

    @spam_stream_resistance.filter_1(key, max_count_of_request, lifetime_of_the_key, increas_time)

    assert @spam_stream_resistance.filter_key_exists?(filter_name, key)

      @spam_stream_resistance.delete_key_from_filter(filter_name, key)
    
    assert @spam_stream_resistance.filter_key_exists?(filter_name, key) == false
    
    

  end

  def test_should_add_new_filter
    
    filter_name = "true_false"
    lua_script = <<-EOF
      local arg1  = tonumber( KEYS[1] )
      local arg2  = tonumber( KEYS[2] )
      return arg1 + arg2
    EOF

    params = [1, 2]

    @spam_stream_resistance.add_filter(filter_name, lua_script)

    assert @spam_stream_resistance.filter_exist?(filter_name), "should exist"

    assert @spam_stream_resistance.execute_filter_by_name(filter_name, params) == 3, "should be 3"

  end
end
