class SpamStreamResistance::WhiteBlackList
  WHITE_LIST_NAMED = "white_list"
  BLACK_LIST_NAMED = "black_list"	

  def initialize(redis_pool)
    @redis_pool = redis_pool
  end

  def redis_pool
    @redis_pool
  end


  def add_in_black(name_of_list = "", keys = [])
  	res = false
    @redis_pool.with do |redis|
      res = redis.sadd "#{BLACK_LIST_NAMED}:#{name_of_list}", keys
    end

    res
  end

  #1 if the timeout was set.
  #0 if key does not exist or the timeout could not be set.
  def black_list_set_expire(name_of_list, seconds)
    res = 0
    @redis_pool.with do |redis|
      res = redis.expire "#{BLACK_LIST_NAMED}:#{name_of_list}", seconds
    end

    res
  end

  #The command returns -2 if the key does not exist.
  #The command returns -1 if the key exists but has no associated expire
  def black_list_check_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.ttl "#{BLACK_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  #1 if the timeout was removed.
  #0 if key does not exist or does not have an associated timeout.
  def black_list_delete_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.persist "#{BLACK_LIST_NAMED}:#{name_of_list}"
    end

    res
  end


  def black_list_include?(name_of_list, key)
  	res = false
    @redis_pool.with do |redis|
      res = redis.sismember "#{BLACK_LIST_NAMED}:#{name_of_list}", key
    end

    res
  end

   def view_all_keys_from_black_list(name_of_list)
    res = []
    @redis_pool.with do |redis|
      res = redis.smembers "#{BLACK_LIST_NAMED}:#{name_of_list}"
    end
    res
  end

  def black_list_exist?(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.exists "#{BLACK_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  def delete_black_list(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.del "#{BLACK_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  def delete_keys_from_black_list(name_of_list, keys)
    res = false
    @redis_pool.with do |redis|
      res = redis.srem "#{BLACK_LIST_NAMED}:#{name_of_list}", keys
    end

    res
  end



  ##white list
  def add_in_white(name_of_list = "", keys = [])
  	res = false
    @redis_pool.with do |redis|
      res = redis.sadd "#{WHITE_LIST_NAMED}:#{name_of_list}", keys
    end

    res
  end

  def white_list_include?(name_of_list, key)
  	res = false
    @redis_pool.with do |redis|
      res = redis.sismember "#{WHITE_LIST_NAMED}:#{name_of_list}", key
    end

    res
  end

  def view_all_keys_from_white_list(name_of_list)
    res = []
    @redis_pool.with do |redis|
      res = redis.smembers "#{WHITE_LIST_NAMED}:#{name_of_list}"
    end
    res
  end

  def white_list_exist?(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.exists "#{WHITE_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  def delete_white_list(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.del "#{WHITE_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  def delete_keys_from_white_list(name_of_list, keys)
    res = false
    @redis_pool.with do |redis|
      res = redis.srem "#{WHITE_LIST_NAMED}:#{name_of_list}", keys
    end

    res
  end

  #1 if the timeout was set.
  #0 if key does not exist or the timeout could not be set.
  def white_list_set_expire(name_of_list, seconds)
    res = 0
    @redis_pool.with do |redis|
      res = redis.expire "#{WHITE_LIST_NAMED}:#{name_of_list}", seconds
    end

    res
  end

  #The command returns -2 if the key does not exist.
  #The command returns -1 if the key exists but has no associated expire
  def white_list_check_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.ttl "#{WHITE_LIST_NAMED}:#{name_of_list}"
    end

    res
  end

  #1 if the timeout was removed.
  #0 if key does not exist or does not have an associated timeout.
  def white_list_delete_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.persist "#{WHITE_LIST_NAMED}:#{name_of_list}"
    end

    res
  end
end