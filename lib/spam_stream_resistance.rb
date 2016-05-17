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
  
  def is_it_spam(str, filter_id, sett_id)
    send("filter_#{filter_id}", filter_id, sett_id)
  end

  private
    def filter_1(sett_id)
 
      #true/false
    end
end
