require 'minitest_helper'

#rake test TEST=test/test_spam_stream_resistance.rb
class TestSpamStreamResistance < Minitest::Test
  def setup
  	#default settings { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} }
    @spam_stream_resistance = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
  end

  def test_object_should_has_three_standart_filters
    #[filter_1, filter_2, filter_3]
    filters_list = @spam_stream_resistance.filters_list

    assert filters_list.include?("filter_1"), "Filter 1 does not exist"
    assert filters_list.include?("filter_2"), "Filter 2 does not exist"
    assert filters_list.include?("filter_3"), "Filter 3 does not exist"
  end
end
