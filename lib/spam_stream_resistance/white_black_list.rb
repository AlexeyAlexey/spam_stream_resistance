class SpamStreamResistance::WhiteBlackList
  WHITE_LIST_NAMED = "white_list"
  BLACK_LIST_NAMED = "black_list"	

  def initialize(redis_pool)
    @redis_pool = redis_pool
  end

  def redis_pool
    @redis_pool
  end

end