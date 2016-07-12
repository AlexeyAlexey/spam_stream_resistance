require 'minitest_helper'

# rake test TEST=test/spam_stream_resistance/test_redis_scripts.rb

class SpamStreamResistance::TestRedisScripts < Minitest::Test
  def setup
  	redis_sett           = {host: 'localhost', port: 6379}
  	connection_pool_sett = {size: 5, timeout: 2}

  	@redis_pool_1 = ConnectionPool.new(connection_pool_sett) { Redis.new(redis_sett) }
  	@redis_pool_2 = ConnectionPool.new(connection_pool_sett) { Redis.new(redis_sett) }

    #delete all script from redis
    @redis_pool_1.with do |redis|
      redis.script 'flush'
    end

    @redis_scripts_1 = SpamStreamResistance::RedisScripts.new(@redis_pool_1)
    @redis_scripts_2 = SpamStreamResistance::RedisScripts.new(@redis_pool_2)

  end

  def test_add_scripts
    added_scripts = @redis_scripts_1.add_scripts({set_string_value: redis_lua_script_set_string_value, get_string_value: redis_lua_script_get_string_value})
    #added_scripts = {set_string_value: sha1, get_string_value: sha1}
    #check if script was loaded
    script_loaded = [false, false]
    @redis_pool_1.with do |redis|
      script_loaded = redis.script 'exists', [(added_scripts[:set_string_value] || ""), (added_scripts[:get_string_value] || "")]
    end
    script_loaded.each do |loaded|
      assert loaded, "Script was not loaded"
    end

    #the same connection must have the same functions
    script_loaded_2 = [false, false]
    @redis_pool_2.with do |redis|
      script_loaded_2 = redis.script 'exists', [(added_scripts[:set_string_value] || ""), (added_scripts[:get_string_value] || "")]
    end
    script_loaded_2.each do |loaded_2|
      assert loaded_2, "the same connection does not have the same function"
    end
  end

  def test_the_same_connection_must_have_the_same_functions
    added_scripts = @redis_scripts_1.add_scripts({set_string_value: redis_lua_script_set_string_value, get_string_value: redis_lua_script_get_string_value})
    #added_scripts = {set_string_value: sha1, get_string_value: sha1}
    @redis_pool_1.with do |redis|
      redis.script 'exists', [(added_scripts[:set_string_value] || ""), (added_scripts[:get_string_value] || "")]
    end

    #the same connection must have the same functions
    script_loaded_2 = [false, false]
    @redis_pool_2.with do |redis|
      script_loaded_2 = redis.script 'exists', [(added_scripts[:set_string_value] || ""), (added_scripts[:get_string_value] || "")]
    end
    script_loaded_2.each do |loaded_2|
      assert loaded_2, "Redis Connection 2: The same connection does not have the same functions"
    end
  end

  def test_execute_script_by_name
    @redis_scripts_1.add_scripts({set_string_value: redis_lua_script_set_string_value, get_string_value: redis_lua_script_get_string_value})
   
    @redis_pool_1.with do |redis|
      redis.del 'key_script_set_string'
    end
    @redis_scripts_1.execute_script_by_name(:set_string_value, ["key_script_set_string", "value_script_set_string"])

    value_of_key = ""
    @redis_pool_1.with do |redis|
      value_of_key = redis.get "key_script_set_string"
    end

    assert (value_of_key == "value_script_set_string"), "Function must set value equal  'value_script_set_string' "
  end

  def test_get_list_of_scripts
    @redis_scripts_1.add_scripts({set_string_value: redis_lua_script_set_string_value, get_string_value: redis_lua_script_get_string_value})
    list_of_scripts = @redis_scripts_1.list_of_scripts
    
    assert (list_of_scripts.keys == ["set_string_value", "get_string_value"]), "Should return set_string_value and get_string_value"
  end

  def test_filter_exist
    @redis_scripts_1.add_scripts({set_string_value: redis_lua_script_set_string_value})
    
    assert @redis_scripts_1.script_exists?(:set_string_value), "should exist"
    assert @redis_scripts_1.script_exists?(:set_string_value_1) == false, "should not exist"
  end


  def redis_lua_script_set_string_value
  	<<-EOF
      return redis.call('set', KEYS[1], KEYS[2])
  	EOF
  end

  def redis_lua_script_get_string_value
  	<<-EOF
      return redis.call('get', KEYS[1])
  	EOF
  end

end