require 'minitest_helper'

#rake test TEST=test/test_spam_stream_resistance.rb
#rake test TEST=test/test_spam_stream_resistance.rb TESTOPTS="--name=test_should_add_new_filter -v"
class TestSpamStreamResistance < Minitest::Test
  def setup
  	#default settings { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} }
    #Flush the Lua scripts cache 
    @redis = Redis.new({host: 'localhost', port: 6379, db: 10})
    @redis.script "FLUSH"
    @spam = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
    
  end

  def test_user_can_use_already_exist_three_lua_scripts
    #[filter_spam_stream, filter_2, filter_3]
    
    @spam.add_filter("filter_spam_stream", @spam.lua_redis_filter_spam_stream)
    @spam.add_filter("filter_2", @spam.lua_redis_filter_2)
    @spam.add_filter("filter_3", @spam.lua_redis_filter_3)

    filters_list = @spam.filters_list

    assert filters_list.include?("filter_spam_stream"), "Filter 1 does not exist"
    assert filters_list.include?("filter_2"), "Filter 2 does not exist"
    assert filters_list.include?("filter_3"), "Filter 3 does not exist"
  end

  def test_filter_spam_stream_must_be_spam
    #key - email address or something else. (string type)
    #increas_time - seconds
    # Count of requests is stored in a key
    # Filter checks if count of requests in a key (email address) less than can be in a lifetime of the key
    # If count of requests more than can be, the filter will increase the lifetime of the key (email address) on increas_time
    #but will not increase count of requests that associated with key
    #but will not increase count of requests in key
    # filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)
    #If count of requests more than can be, the filter_spam_stream return true else false
    #If the filter_spam_stream return empty string, it might be something wrong
    
    key = "user@mail.com"
    max_number_of_requests = 10
    lifetime_of_the_key  = 7
    increas_time         = 5

    #if spam return true else return false

    
    @redis.get "filter_spam_stream:#{key}"

    #create filter
    @spam.add_filter("filter_spam_stream", @spam.lua_redis_filter_spam_stream)
    
    measure_the_time = Benchmark.measure do 
      10.times do |i|
        #@spam.filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)
        @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time])
      end
    end

    assert @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time]) and measure_the_time.real < lifetime_of_the_key

  end

  def test_filter_spam_stream_must_not_be_spam_time_expired
    #key - email address or something else. (string type)
    #increas_time - seconds
    # Count of requests is stored in a key
    # Filter checks if count of requests in a key (email address) less than can be in a lifetime of the key
    # If count of requests more than can be, the filter will increase the lifetime of the key (email address) on increas_time
    #but will not increase count of requests that associated with key
    #but will not increase count of requests in key
    # filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)
    #If count of requests more than can be, the filter_spam_stream return true else false
    #If the filter_spam_stream return empty string, it might be something wrong
    
    key = "user@mail.com"
    max_number_of_requests = 10
    lifetime_of_the_key  = 7
    increas_time         = 5

    #if spam return 1 else return nil
    @spam.add_filter("filter_spam_stream", @spam.lua_redis_filter_spam_stream)
    
    @redis.del "filter_spam_stream:#{key}"
    
    measure_the_time = Benchmark.measure do 
      10.times do |i|
        #@spam.filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)
        @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time])
      end
    end
    
    time_sleep = lifetime_of_the_key + increas_time
  
    sleep (time_sleep)

    assert !@spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time])

  end

  def test_key_exist_in_filter
    key = "user@mail.com"
    max_number_of_requests = 10
    lifetime_of_the_key  = 60
    increas_time         = 5

    filter_name = "filter_spam_stream"
    
    @redis.del "#{filter_name}:#{key}"

    @spam.add_filter(filter_name, @spam.lua_redis_filter_spam_stream)
    @spam.execute_filter_by_name(filter_name ,[key, max_number_of_requests, lifetime_of_the_key, increas_time])

    assert @spam.filter_key_exists?(filter_name, key)
  end

  def test_delete_key_from_filter
    key = "user@mail.com"
    filter_name = "filter_spam_stream"

    max_number_of_requests = 10
    lifetime_of_the_key  = 60
    increas_time         = 5
    
    @redis.del "#{filter_name}:#{key}"

    @spam.add_filter(filter_name, @spam.lua_redis_filter_spam_stream)
    @spam.execute_filter_by_name(filter_name, [key, max_number_of_requests, lifetime_of_the_key, increas_time])

    #@spam.filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)

    assert @spam.filter_key_exists?(filter_name, key)

    @spam.delete_key_from_filter(filter_name, key)
    
    assert @spam.filter_key_exists?(filter_name, key) == false
    
    

  end

  def test_should_add_new_filter
    
    filter_name = "true_false"
    lua_script = <<-EOF
      local key   = KEYS[1]
      local arg2  = tonumber( KEYS[2] )
      local arg3  = tonumber( KEYS[3] )
      return arg2 + arg3
    EOF

    key = "123"
    params = [key, 1, 2]

    @spam.add_filter(filter_name, lua_script)

    assert @spam.filter_exist?(filter_name), "should exist"

    assert @spam.execute_filter_by_name(filter_name, params) == 3, "should be 3"

  end

  def test_filter_time_of_key
    key = "user@mail.com"
    filter_name = "filter_spam_stream"

    max_number_of_requests = 1
    lifetime_of_the_key  = 60
    increas_time         = 1
        
    @redis.del "#{filter_name}:#{key}"

    @spam.add_filter(filter_name, @spam.lua_redis_filter_spam_stream)
    @spam.execute_filter_by_name(filter_name, [key, max_number_of_requests, lifetime_of_the_key, increas_time])

    
    assert @spam.filter_time_of_key(filter_name, key) > 55
  end
end
