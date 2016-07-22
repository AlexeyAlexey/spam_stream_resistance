require 'minitest_helper'

# rake test TEST=test/spam_stream_resistance/test_white_black_list.rb

class SpamStreamResistance::TestWhiteBlackList < Minitest::Test
  def setup
  	redis_sett           = {host: 'localhost', port: 6379}
  	connection_pool_sett = {size: 5, timeout: 2}

  	@redis_pool = ConnectionPool.new(connection_pool_sett) { Redis.new(redis_sett) }
  	
    
    #delete all script from redis
    #@redis_pool.with do |redis|
    #  redis.del SpamStreamResistance::WhiteBlackList::WHITE_LIST_NAMED
    #  redis.del SpamStreamResistance::WhiteBlackList::BLACK_LIST_NAMED
    #end
  end

  def test_add_in_black_list
    white_black_list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_black_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    white_black_list.add_in_black(name_of_black_list, keys)
    
    assert white_black_list.black_list_exist?(name_of_black_list)

    assert white_black_list.black_list_include?(name_of_black_list, keys[0])
    assert white_black_list.black_list_include?(name_of_black_list, keys[1])

    assert white_black_list.delete_black_list(name_of_black_list)
    assert white_black_list.black_list_exist?(name_of_black_list) == false

    
  end

  def test_add_in_white_list
    white_black_list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_white_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    white_black_list.add_in_white(name_of_white_list, keys)
    
    assert white_black_list.white_list_exist?(name_of_white_list)

    assert white_black_list.white_list_include?(name_of_white_list, keys[0])
    assert white_black_list.white_list_include?(name_of_white_list, keys[1])

    assert white_black_list.delete_white_list(name_of_white_list)
    assert white_black_list.white_list_exist?(name_of_white_list) == false

    
  end


end


