class SpamStreamResistance::RedisScripts
  HASH_SCRIPTS_NAME = "sp_str_res_redis_scripts"

  def initialize(redis_pool)
    @redis_pool = redis_pool
    
    update_scripts

    @sha1_function_add_scripts = ""
    #load scripts
    sha1_add_scripts = ""
    @redis_pool.with do |redis|
      sha1_add_scripts = redis.script 'load', lua_add_scripts
      unless sha1_add_scripts.empty?
        redis.evalsha sha1_add_scripts, [HASH_SCRIPTS_NAME, "add_scripts", sha1_add_scripts]
        @sha1_function_add_scripts = sha1_add_scripts
      end
    end
  end

  def update_scripts
    @redis_pool.with do |redis|
      sha1_scripts_list = redis.hgetall HASH_SCRIPTS_NAME
      sha1_scripts_list_values = sha1_scripts_list.values
      sha1_scripts_list_keys   = sha1_scripts_list.keys
      
      sha1_script_exists = redis.script 'exists', sha1_scripts_list_values
      delete_keys = []

      sha1_script_exists.each_with_index do |value, index|
        unless value 
          delete_keys << sha1_scripts_list_keys[index]
        end
      end

      unless delete_keys.empty?
        redis.hdel HASH_SCRIPTS_NAME, delete_keys
      end
    end
  end

  def add_scripts(scripts = {})
    loaded = {}
    scripts.each_pair do |script_name, script_str|
      @redis_pool.with do |redis|
        sha1_script = redis.script 'load', script_str
        unless sha1_script.empty?
          res = redis.evalsha( @sha1_function_add_scripts, [HASH_SCRIPTS_NAME, "#{script_name}", sha1_script] )
          unless res.nil?
            loaded[script_name] = sha1_script
          end
        end
      end
    end
    loaded
  end

  def script_exists(name)
    sha1_script = ""
    @redis_pool.with do |redis|
      sha1_script = redis.hgetall HASH_SCRIPTS_NAME, "#{name}"
    end
    !sha1_script.empty?
  end


  def all_scripts
    scripts = {}
    @redis_pool.with do |redis|
      scripts = redis.hgetall HASH_SCRIPTS_NAME
    end
    scripts
  end

  def execute_script_by_name(function_name, function_params = [])
    ""
  end

  def redis_pool
    @redis_pool
  end


  #scripts_have_not_been_loaded in redis
  private
    def lua_add_scripts
      <<-EOF
        local hash_name     = KEYS[1]
        local script_name   = KEYS[2]
        local script_sha1   = KEYS[3]
        local script_exist

        script_exist  = redis.call('hexists', hash_name, script_name)
        
        if (script_exist == 1) then
          return false
        else
          return ( redis.call('hset', hash_name, script_name, script_sha1) )
        end
      EOF
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