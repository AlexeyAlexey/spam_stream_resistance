require "spam_stream_resistance/version"
require 'spam_stream_resistance/redis_scripts'
require 'spam_stream_resistance/white_black_list'

#Class has three standard lua scripts for filtering (lua_redis_filter_spam_stream, lua_redis_filter_2, lua_redis_filter_3)
#It is three methods lua_redis_filter_spam_stream, lua_redis_filter_2, lua_redis_filter_3 that return lua script as string

class SpamStreamResistance
  #save filter settings in redis hash 
  HASH_KEY_FILTER_SETTINGS = "sp_stream_res_filter_set"
  
  def initialize(redis_sett = { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} })
    @redis_pool = ConnectionPool.new(redis_sett[:connection_pool]) { Redis.new(redis_sett[:redis]) }
    
    @redis_script_menager = RedisScripts.new(@redis_pool)

    @white_black_list = WhiteBlackList.new(@redis_pool)

  end

  def redis_pool
    @redis_pool
  end


  def filters_list
    @redis_script_menager.list_of_scripts.keys
  end

  #def filter_spam_stream(key, max_number_of_requests, lifetime_of_the_key, increas_time)
    #"filter_spam_stream::#{key}"
    #if spam return 1 else return nil
  #  res = @redis_script_menager.execute_script_by_name("filter_spam_stream", ["filter_spam_stream:#{key}", max_number_of_requests, lifetime_of_the_key, increas_time])
  #  if res == 1
  #    return true
  #  elsif res.nil?
  #    return false
  #  else
      #something wrong
  #    return ""
  #  end
  #end

  def execute_filter_by_name(filter_name, params)
    params[0] = "#{filter_name}:#{params[0]}"
    @redis_script_menager.execute_script_by_name(filter_name, params)
  end

  def filter_key_exists?(filter, key)
    exist = false
    @redis_pool.with do |redis|
      exist = redis.exists "#{filter}:#{key}"
    end
    exist
  end

  def filter_time_of_key(filter, key)
    time = 0
    @redis_pool.with do |redis|
      time = redis.ttl "#{filter}:#{key}"
    end
    time
  end

  def delete_key_from_filter(filter, key)
    @redis_pool.with do |redis|
      redis.del "#{filter}:#{key}"
    end
  end

  def add_filter(name, lua_script)
    @redis_script_menager.add_scripts({name => lua_script})
  end

  def filter_exist?(name)
    @redis_script_menager.script_exists?(name)
  end

 
    #def init_filters
    #  @redis_script_menager.add_scripts({filter_spam_stream: lua_redis_filter_spam_stream, 
    #                                     filter_2: lua_redis_filter_2,
    #                                     filter_3: lua_redis_filter_3
    #                                    })
    #end

  #filter_spam_stream realises the following logics
  #key - an email address or something else. (string type)
  #increas_time - seconds (increase_time)
  #max_number_of_requests - max count of requests (max_number_of_requests)
  #The number of requests is stored in a key
  #The filter checks if the number of requests in a key (email address) is lower than can be in a lifetime of the key
  #If the number of requests is higher than can be, the filter will increase the lifetime of the key (email address) on increas_time
  #but will not increase the number of requests that are associated with the key
  #If the number of requests is higher than can be, the filter_spam_stream returns 1 (spam) or nil (not spam)
  #If the filter_spam_stream returns the empty string, there might be something wrong
  def lua_redis_filter_spam_stream
    <<-EOF
      local key = KEYS[1]
      local max_number_of_requests = tonumber( KEYS[2] )
      local expire = tonumber( KEYS[3] )
      local increas_time = KEYS[4]
      local is_spam = true
      local is_not_spam = false
      local red_expire
      local red_count
      

      red_count  = tonumber( redis.call('get', key) )
      red_expire = redis.call('ttl', key)
      
      if (red_expire == -2) then
        redis.call('incr', key)
        redis.call('expire', key, expire)
        return is_not_spam
      end

      if (red_count >= max_number_of_requests) then
        redis.call('expire', key, (red_expire + increas_time))
        return is_spam
      else
        redis.call('incr', key)
        redis.call('expire', key, red_expire)
        return is_not_spam
      end
      
      return ""
    EOF
  end

  def lua_redis_filter_2
    <<-EOF
      return ""
    EOF
  end

  def lua_redis_filter_3
    <<-EOF
      local key = KEYS[1]
      local max_number_of_requests = tonumber( KEYS[2] )
      local expire = tonumber( KEYS[3] )
      local increas_time = KEYS[4]
      local is_spam = true
      local is_not_spam = false
      local red_expire
      local red_count
      

      red_count  = tonumber( redis.call('get', key) )
      red_expire = redis.call('ttl', key)
      
      if (red_expire == -2) then
        redis.call('incr', key)
        redis.call('expire', key, expire)
        return is_not_spam
      end

      if (red_count >= max_number_of_requests) then
        redis.call('expire', key, (red_expire + increas_time))
        return is_spam
      else
        redis.call('incr', key)
        redis.call('expire', key, red_expire)
        return is_not_spam
      end
      
      return ""
    EOF
  end


end
