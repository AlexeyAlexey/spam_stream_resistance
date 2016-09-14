class SpamStreamResistance::List
  
  def initialize(redis_pool)
    @redis_pool = redis_pool
  end

  def redis_pool
    @redis_pool
  end


  def add_in_list(name_of_list = "", keys = [])
  	res = false
    @redis_pool.with do |redis|
      res = redis.sadd "#{name_of_list}", keys
    end

    res
  end

  #1 if the timeout was set.
  #0 if key does not exist or the timeout could not be set.
  def list_set_expire(name_of_list, seconds)
    res = 0
    @redis_pool.with do |redis|
      res = redis.expire "#{name_of_list}", seconds
    end

    res
  end

  #The command returns -2 if the key does not exist.
  #The command returns -1 if the key exists but has no associated expire
  def list_check_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.ttl "#{name_of_list}"
    end

    res
  end

  #1 if the timeout was removed.
  #0 if key does not exist or does not have an associated timeout.
  def list_delete_expire(name_of_list)
    res = -2
    @redis_pool.with do |redis|
      res = redis.persist "#{name_of_list}"
    end

    res
  end


  def list_include?(name_of_list, key)
  	res = false
    @redis_pool.with do |redis|
      res = redis.sismember "#{name_of_list}", key
    end

    res
  end

   def view_all_keys_from_list(name_of_list)
    res = []
    @redis_pool.with do |redis|
      res = redis.smembers "#{name_of_list}"
    end
    res
  end

  def list_exist?(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.exists "#{name_of_list}"
    end

    res
  end

  def delete_list(name_of_list)
    res = false
    @redis_pool.with do |redis|
      res = redis.del "#{name_of_list}"
    end

    res
  end

  def delete_keys_from_list(name_of_list, keys)
    res = false
    @redis_pool.with do |redis|
      res = redis.srem "#{name_of_list}", keys
    end

    res
  end


end