require 'minitest_helper'

class TestSpamStreamResistance < Minitest::Test
  def setup
  	#default settings { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} }
    @spam_stream_resistance = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
  end

  def test_that_it_has_a_version_number
    refute_nil ::SpamStreamResistance::VERSION
  end

  def test_redis_pool
    assert_equal "ConnectionPool", @spam_stream_resistance.redis_pool.class.name

    #@spam_stream_resistance.redis_pool.with do |redis|
    #  redis.lpush 'process_action_controller', "1"
    #end
    
    #@spam_stream_resistance.redis_pool.with do |redis|
    #  redis.lpop 'process_action_controller', "1"
    #end
  end

  def test_settings_filter_id
  	filter_id   = "1"
  	settings_id = "1"

    @spam_stream_resistance.init_settings_filter_id(filter_id)
    
    assert_equal ({ filter_id => {} }), @spam_stream_resistance.settings_filter_id

    @spam_stream_resistance.settings_filter_id_add(filter_id, { settings_id => {max_count_request: 10, expire: 20, increas_time: 10} })
    
    assert_equal ( {max_count_request: 10, expire: 20, increas_time: 10} ), @spam_stream_resistance.settings_filter_by_id(filter_id, settings_id), "settings_filter_by_id"
  
  @spam_stream_resistance.is_it_spam("str", filter_id, settings_id)

    @spam_stream_resistance.settings_filter_id_delete(filter_id, settings_id)

    assert_equal ({ filter_id => {} }), @spam_stream_resistance.settings_filter_id

    
  end
end
