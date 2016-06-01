require "spam_stream_resistance/version"
require 'spam_stream_resistance/redis_scripts'

#Class has three standard filters (filter_1, filter_2, filter_3)
class SpamStreamResistance
  #save filter settings in redis hash 
  HASH_KEY_FILTER_SETTINGS = "sp_stream_res_filter_set"
  
  def initialize(redis_sett = { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} })
    @redis_pool = ConnectionPool.new(redis_sett[:connection_pool]) { Redis.new(redis_sett[:redis]) }
    
    @redis_script_menager = RedisScripts.new(@redis_pool)

    init_filters


  end

  def redis_pool
    @redis_pool
  end


  def filters_list
    @redis_script_menager.list_of_scripts.keys
  end

 

  private
    def init_filters
      @redis_script_menager.add_scripts({filter_1: lua_redis_filter_1, 
                                         filter_2: lua_redis_filter_2,
                                         filter_3: lua_redis_filter_3
                                        })
    end


    def lua_redis_filter_1
      <<-EOF
        local key = KEYS[1]
        local max_count_request = KEYS[2]
        local expire = KEYS[3]
        local increas_time = KEYS[4]
        local is_spam = true
        local is_not_spam = false
        local red_expire
        local red_count
        

        red_count  = redis.call('get', key)
        red_expire = redis.call('ttl', key)

        if (red_expire == -2) then
          redis.call('incr', key)
          redis.call('expire', key, expire)
          return is_not_spam
        end

        if (red_count >= max_count_request) then
          redis.call('expire', key, (red_expire + increas_time))
          return is_spam
        else
          redis.call('incr', key)
          redis.call('expire', key, (red_expire + increas_time))
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
        return ""
      EOF
    end


end
