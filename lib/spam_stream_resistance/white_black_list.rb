class SpamStreamResistance::WhiteBlackList
  WHITE_LIST_NAMED = "white_list"
  BLACK_LIST_NAMED = "black_list"	

  def initialize(redis_pool)
    @redis_pool = redis_pool
  end

  def redis_pool
    @redis_pool
  end


  def add_in_black(name_of_black_list = "", keys = [])
  	res = false
    @redis_pool.with do |redis|
      res = redis.sadd "#{BLACK_LIST_NAMED}:#{name_of_black_list}", keys
    end

    res
  end

  def black_list_include?(name_of_black_list, key)
  	res = false
    @redis_pool.with do |redis|
      res = redis.sismember "#{BLACK_LIST_NAMED}:#{name_of_black_list}", key
    end

    res
  end

  def black_list_exist?(name_of_black_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.exists "#{BLACK_LIST_NAMED}:#{name_of_black_list}"
    end

    res
  end

  def delete_black_list(name_of_black_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.del "#{BLACK_LIST_NAMED}:#{name_of_black_list}"
    end

    res
  end



  ##white list
  def add_in_white(name_of_white_list = "", keys = [])
  	res = false
    @redis_pool.with do |redis|
      res = redis.sadd "#{WHITE_LIST_NAMED}:#{name_of_white_list}", keys
    end

    res
  end

  def white_list_include?(name_of_white_list, key)
  	res = false
    @redis_pool.with do |redis|
      res = redis.sismember "#{WHITE_LIST_NAMED}:#{name_of_white_list}", key
    end

    res
  end

  def white_list_exist?(name_of_white_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.exists "#{WHITE_LIST_NAMED}:#{name_of_white_list}"
    end

    res
  end

  def delete_white_list(name_of_white_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.del "#{WHITE_LIST_NAMED}:#{name_of_white_list}"
    end

    res
  end


end