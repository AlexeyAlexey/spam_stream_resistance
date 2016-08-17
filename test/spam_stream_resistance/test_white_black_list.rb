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
    list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    list.add_in_black(name_of_list, keys)
    
    assert list.black_list_exist?(name_of_list)

    assert list.black_list_include?(name_of_list, keys[0])
    assert list.black_list_include?(name_of_list, keys[1])

    assert list.delete_keys_from_black_list(name_of_list, [ keys[1] ])
    assert list.black_list_include?(name_of_list, keys[1]) == false

    assert list.delete_black_list(name_of_list)
    assert list.black_list_exist?(name_of_list) == false

    
  end

  def test_add_in_white_list
    list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    list.add_in_white(name_of_list, keys)
    
    assert list.white_list_exist?(name_of_list)

    assert list.white_list_include?(name_of_list, keys[0])
    assert list.white_list_include?(name_of_list, keys[1])

    assert list.delete_keys_from_white_list(name_of_list, [ keys[1] ])
    assert list.white_list_include?(name_of_list, keys[1]) == false

    assert list.delete_white_list(name_of_list)
    assert list.white_list_exist?(name_of_list) == false

    
  end

  def test_black_list_expire
    expire = 5 #seconds
    
    list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    list.add_in_black(name_of_list, keys)
    
    assert list.black_list_exist?(name_of_list)

    assert list.black_list_include?(name_of_list, keys[0])
    assert list.black_list_include?(name_of_list, keys[1])

    assert list.black_list_set_expire(name_of_list, 10)
    
    #add delete
    list.add_in_black(name_of_list, ["add_new_key"])
    
    assert list.black_list_include?(name_of_list, ["add_new_key"])
    
    list.delete_keys_from_black_list(name_of_list, ["add_new_key"])

    assert list.black_list_include?(name_of_list, "add_new_key") == false
    #

    #check time
    assert list.black_list_check_expire(name_of_list) > 5

    assert list.black_list_delete_expire(name_of_list)

    assert list.black_list_check_expire(name_of_list) == -1

  end

  def test_white_list_expire
    expire = 5 #seconds
    
    list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

    name_of_list = "list_1"
    keys  = ["1@mail.com", "2@mail.com"]

    list.add_in_white(name_of_list, keys)
    
    assert list.white_list_exist?(name_of_list)

    assert list.white_list_include?(name_of_list, keys[0])
    assert list.white_list_include?(name_of_list, keys[1])

    assert list.white_list_set_expire(name_of_list, 10)
    
    #add delete
    list.add_in_white(name_of_list, ["add_new_key"])
    
    assert list.white_list_include?(name_of_list, ["add_new_key"])
    
    list.delete_keys_from_white_list(name_of_list, ["add_new_key"])

    assert list.white_list_include?(name_of_list, "add_new_key") == false
    #

    #check time
    assert list.white_list_check_expire(name_of_list) > 5

    assert list.white_list_delete_expire(name_of_list)

    assert list.white_list_check_expire(name_of_list) == -1

  end


end


