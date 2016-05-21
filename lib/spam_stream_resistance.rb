require "spam_stream_resistance/version"

class SpamStreamResistance
  
  def initialize(redis_sett = { redis: {host: 'localhost', port: 6379}, connection_pool: {size: 5, timeout: 2} })
    @redis_pool = ConnectionPool.new(redis_sett[:connection_pool]) { Redis.new(redis_sett[:redis]) }
    
    @settings_filter_id = {}
  end

  def redis_pool
    @redis_pool
  end

  def settings_filter_id
    @settings_filter_id
  end
  #init settings of filter 
  def init_settings_filter_id(filter_id, sett = {})
    #{filter_id: {}}
    @settings_filter_id[filter_id] = sett
  end
   
  def settings_filter_id_add(filter_id, sett = {})
    #sett = { settings_id => {max_count_request: 10, expire: 20, increas_time: 10} }
  	#{filter_id: {settings_id: {}}, filter_id: {settings_id: {}}}
  	@settings_filter_id[filter_id].merge!(sett)
  end

  def settings_filter_id_delete(filter_id = nil, sett_id = nil)
  	#{filter_id: {settings_id: {}}, filter_id: {settings_id: {}}}
    @settings_filter_id[filter_id].delete(sett_id)
  end

  def settings_filter_by_id(filter_id = nil, sett_id = nil)
  	#{filter_id: {settings_id: {}}, filter_id: {settings_id: {}}}
    @settings_filter_id[filter_id][sett_id]
  end



  def look_at(str, filter_id, sett_id)
  	send("filter_#{filter_id}", filter_id, sett_id)
  end
  
  def is_it_spam(str, filter_id, sett_id, &block)
    #yield if block_given?
    send("filter_#{filter_id}", str, sett_id, &block)
  end

  private
    def filter_1(str, sett_id, &block)
      #{"1" => { sett_id => { max_count_request: 5, expire: 2, increas_time: 2 }, "" => {}, ... } }
      #{ max_count_request: 5, expire: 2, increas_time: 2 }
      #@redis_pool.redis_pool.with do |redis|
      #  redis. "1:#{sett_id}:#{str}", "1"
      #end
      #Lua script
      #(key)KEYS[1] (max_count_request)KEYS[2] (expire)KEYS[3] (increas_time)KEYS[4]
      #false  is not spam
      #true   is spam
      fn_redis_filter_1 = <<-EOF
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



      is_spam = nil
      key = "1:#{sett_id}:#{str}"

      settings = @settings_filter_id["1"][sett_id]
      max_count_request = settings[:max_count_request]
      expire            = settings[:expire]
      increas_time      = settings[:increas_time]
            
      @redis_pool.with do |redis|
byebug
        redis.eval(fn_redis_filter_1, [key, max_count_request, expire, increas_time])
        #redis.evalsha("4e6d8fc8bb01276962cce5371fa795a7763657ae", [""])
      end
      

      if block_given?
        case block.arity
          when 0
            yield
          when 1
            yield is_spam
          when 2
            yield is_spam, self
        end
      end
 
      #true/false
    end

    



    def function_redis_filter_1
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


end
