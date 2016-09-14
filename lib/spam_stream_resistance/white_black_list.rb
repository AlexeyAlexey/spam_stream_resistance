class SpamStreamResistance::WhiteBlackList < SpamStreamResistance::List
  WHITE_LIST_NAMED = "white_list"
  BLACK_LIST_NAMED = "black_list"	

  def initialize(redis_pool)
    super
  end

  def redis_pool
    @redis_pool
  end


  def add_in_black(name_of_list = "", keys = [])
  	add_in_list("#{BLACK_LIST_NAMED}:#{name_of_list}", keys)
  end

  #1 if the timeout was set.
  #0 if key does not exist or the timeout could not be set.
  def black_list_set_expire(name_of_list, seconds)
    list_set_expire("#{BLACK_LIST_NAMED}:#{name_of_list}", seconds)
  end

  #The command returns -2 if the key does not exist.
  #The command returns -1 if the key exists but has no associated expire
  def black_list_check_expire(name_of_list)
    list_check_expire("#{BLACK_LIST_NAMED}:#{name_of_list}")
  end

  #1 if the timeout was removed.
  #0 if key does not exist or does not have an associated timeout.
  def black_list_delete_expire(name_of_list)
    list_delete_expire("#{BLACK_LIST_NAMED}:#{name_of_list}")
  end

  def black_list_include?(name_of_list, key)
    list_include?("#{BLACK_LIST_NAMED}:#{name_of_list}", key)
  end

   def view_all_keys_from_black_list(name_of_list)
    view_all_keys_from_list("#{BLACK_LIST_NAMED}:#{name_of_list}")
  end

  def black_list_exist?(name_of_list)
    list_exist?("#{BLACK_LIST_NAMED}:#{name_of_list}")
  end

  def delete_black_list(name_of_list)
    delete_list("#{BLACK_LIST_NAMED}:#{name_of_list}")
  end

  def delete_keys_from_black_list(name_of_list, keys)
    delete_keys_from_list("#{BLACK_LIST_NAMED}:#{name_of_list}", keys)
  end



  ##white list
  def add_in_white(name_of_list = "", keys = [])
    add_in_list("#{WHITE_LIST_NAMED}:#{name_of_list}", keys)
  end

  def white_list_include?(name_of_list, key)
    list_include?("#{WHITE_LIST_NAMED}:#{name_of_list}", key)
  end

  def view_all_keys_from_white_list(name_of_list)
    view_all_keys_from_list("#{WHITE_LIST_NAMED}:#{name_of_list}")
  end

  def white_list_exist?(name_of_list)
    list_exist?("#{WHITE_LIST_NAMED}:#{name_of_list}")
  end

  def delete_white_list(name_of_list)
    delete_list("#{WHITE_LIST_NAMED}:#{name_of_list}")
  end

  def delete_keys_from_white_list(name_of_list, keys)
    delete_keys_from_list("#{WHITE_LIST_NAMED}:#{name_of_list}", keys)
  end

  #1 if the timeout was set.
  #0 if key does not exist or the timeout could not be set.
  def white_list_set_expire(name_of_list, seconds)
    list_set_expire("#{WHITE_LIST_NAMED}:#{name_of_list}", seconds)
  end

  #The command returns -2 if the key does not exist.
  #The command returns -1 if the key exists but has no associated expire
  def white_list_check_expire(name_of_list)
    list_check_expire("#{WHITE_LIST_NAMED}:#{name_of_list}")
  end

  #1 if the timeout was removed.
  #0 if key does not exist or does not have an associated timeout.
  def white_list_delete_expire(name_of_list)
    list_delete_expire("#{WHITE_LIST_NAMED}:#{name_of_list}")
  end
end