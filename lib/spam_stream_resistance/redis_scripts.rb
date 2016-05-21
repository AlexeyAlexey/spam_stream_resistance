class SpamStreamResistance::RedisScripts

  def initialize(redis_pool)
    @redis_pool = redis_pool

    init_redis_script

    @redis_scripts_cache = {}
    @scripts_have_not_been_loaded = {}
  end

  #scripts_have_not_been_loaded in redis
  def scripts_have_not_been_loaded
    @redis_scripts_have_not_been_loaded
  end

  def redis_scripts_by_name

  end

  def redis_scripts_cache
    #{"name": "2bab3b661081db58bd2341920e0ba7cf5dc77b25", ....}
    @redis_scripts_cache = {}
  end

  def redis_scripts_add(scripts = {})
    #script = {"name" => "Lua script"}
    scripts_can_be_added = {}
    scripts.each_pair |script_name, script|
      unless @redis_scripts_cache.include?("#{script_name}")
        scripts_can_be_added["#{script_name}"] = script
      end
    end
    @scripts_have_not_been_loaded.merge!(scripts_can_be_added)

    @redis_scripts.merge!(scripts_can_be_added)
  end

  def load_unloaded_scripts_in_redis

  end

  private
    def init_redis_script
      @redis_scripts = {}
      
      [:filter_1].each do |script_name|
         @redis_scripts["#{script_name}"] = send(script_name)
      end
    end
    
    def scripts_can_be_loaded(scripts = {})
      #scripts = {"name" => "Lua script", ....}
      can_be_loaded = {}
      scripts.each_pair |script_name, script|
        unless @redis_scripts_cache.include?("#{script_name}")
          can_be_loaded["#{script_name}"] = script
        end
      end
      can_be_loaded
    end

    def load_script_in_redis
      #@redis_scripts_cache
      can_be_loaded = scripts_can_be_loaded(@scripts_have_not_been_loaded)
      @redis_pool.with do |redis|
        can_be_loaded.each_pair do |script_name, script|
          @redis_scripts_cache["#{script_name}"] = ( redis.script load script )
        end
      end
      @scripts_have_not_been_loaded = {}

    end
   
    def load_all_scripts_in_redis
      can_be_loaded = scripts_can_be_loaded(@scripts_have_not_been_loaded)

      @redis_pool.with do |redis|
        can_be_loaded.each_pair do |script_name, script|
          @redis_scripts_cache["#{script_name}"] = ( redis.script load script )
        end
      end
    end

    def reload_all_scripts

    end

    def redis_scripts
      #{"name" => "Lua script", "filter_2" => "Lua script", ...}
      @redis_scripts
    end



    def redis_scripts_load(name)
      @redis_pool.with do |redis|
        #@redis_scripts_cache redis.script load ""
      end
    end

#Filter scripts
    def filter_1
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