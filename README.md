# SpamStreamResistance

This library uses the redis and next libraries “redis" and "connection_pool"

- You can use this library as a spam filter. 
- You can add your own filter(scripts) and execute them. (You have to use a key as the first parameter when executing the filter) 
- You can create a blacklist or whitelist with or without time expiration (lifetime) of this list
- You can create your own list with or without time expiration (lifetime) of this list
- You can use a script manager


**Example,  POST API in JSON format:** 

```
{“client_email”: “client@mail.com”,
 ...
}
```
We should send an email to the address that (is value of “client_email” key) we have in the “client_email” key
We know that we can not have more than 10 emails (requests) sent in 10 seconds to the same address


## Use as a Spam Filter

Initialize
```
@spam = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
```
```
#create filter
@spam.add_filter("filter_spam_stream", @spam.lua_redis_filter_spam_stream)
````

**add_filter(filter_named, lua_script_as_string)** the method returns the hash where the key is a name of the script and the value is SHA1 digest of the script or the empty hash if the script with this name already exists


**@spam.lua_redis_filter_spam_stream** returns lua script as string
```ruby
<<-EOF
      local key = KEYS[1]
      local max_count_request = tonumber( KEYS[2] )
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

      if (red_count >= max_count_request) then
        redis.call('expire', key, (red_expire + increas_time))
        return is_spam
      else
        redis.call('incr', key)
        redis.call('expire', key, red_expire)
        return is_not_spam
      end
      
      return ""
EOF
```

**filter_spam_stream** realises the following logics

**key** - an email address or something else. (string type)

**increas_time** - seconds (increase_time)

**max_number_of_requests** - max count of requests (max_number_of_requests)

The number of requests is stored in a **key**
The filter checks if the number of requests in a **key** (email address) is lower than can be in a lifetime of the **key**
If the number of requests is higher than can be, the filter will increase the lifetime of the **key** (email address) on  **increas_time** but will not increase the number of requests that are associated with the **key**
If the number of requests is higher than can be, the filter_spam_stream returns **1** (spam) or **nil** (not spam)
If the **filter_spam_stream** returns the empty string, there might be something wrong


### For executing the filter

```ruby
@spam.execute_filter_by_name( "filter_spam_stream" , [ key, max_number_of_requests, lifetime_of_the_key, increas_time ] )
```

**Example**

```ruby
key = "user@mail.com"
max_number_of_requests = 10
lifetime_of_the_key  = 7
increas_time         = 5

10.times do |i|
  @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time]) #=> nil
 end

@spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time]) #=> 1
```

The method `execute_filter_by_name(name_of_filter_as_string, array_of_params)` takes two parameters. The first parameter is the name of the filter and is the string type. The second parameter is an array of filter parameters.

## We can check if the key exists in the filter

`@spam.filter_key_exists?(filter_name, key)` The method returns true if the key exists in filter or false

**Example**

```ruby
key = "user@mail.com"
max_number_of_requests = 10
lifetime_of_the_key  = 7
increas_time         = 5

10.times do |i|
  @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time]) #=> nil
 end

@spam.filter_key_exists?("filter_spam_stream", key) #=> true
```

### We can delete the key from the filter

@spam.delete_key_from_filter(filter_name, key)

**Example**

```ruby
key = "user@mail.com"
max_number_of_requests = 10
lifetime_of_the_key  = 7
increas_time         = 5

10.times do |i|
  @spam.execute_filter_by_name("filter_spam_stream" ,[key, max_number_of_requests, lifetime_of_the_key, increas_time]) #=> nil
 end

@spam.filter_key_exists?("filter_spam_stream", key) #=> true

@spam.delete_key_from_filter("filter_spam_stream", key)

@spam.filter_key_exists?("filter_spam_stream", key) #=> false
```

### Add your own filter

You have to use a key as the first parameter when executing the filter

**Example**

```ruby
filter_name = "true_false"
lua_script = <<-EOF
      local key   = KEYS[1]
      local arg2  = tonumber( KEYS[2] )
      local arg3  = tonumber( KEYS[3] )
      return arg2 + arg3
EOF

key = "123"
params = [key, 1, 2]

@spam.add_filter(filter_name, lua_script) #=> {"true_false" => “SHA1 digest”}

@spam.filter_exist?(filter_name) #=> true

@spam.execute_filter_by_name(filter_name, params) #=> 3
 
```

### Check lifetime of the key (current lifetime of the key in the filter)

**Example**

```ruby
key = "user@mail.com"
filter_name = "filter_spam_stream"

max_number_of_requests = 1
lifetime_of_the_key  = 60
increas_time         = 1
        
@spam.add_filter(filter_name, @spam.lua_redis_filter_spam_stream)
@spam.execute_filter_by_name(filter_name, [key, max_number_of_requests, lifetime_of_the_key, increas_time])

@spam.filter_time_of_key(filter_name, key) #=>returns the current lifetime of the key in the filter

```


### Return the connection pool (gem "connection_pool")

**Example**

```ruby
@spam.redis_pool.with do |redis|
  exist = redis.exists "#{filter}:#{key}"
end

```


## A blacklist or whitelist or your own list with or without time expiration (lifetime)

### Create a Blacklist

```ruby
redis_sett   = {host: 'localhost', port: 6379}
connection_pool_sett = {size: 5, timeout: 2}

@redis_pool = ConnectionPool.new(connection_pool_sett) { Redis.new(redis_sett) } #(gem "redis"; gem "connection_pool")

#or from the previous chapter 
#@spam = SpamStreamResistance.new({ redis: {host: 'localhost', port: 6379, db: 10}, connection_pool: {size: 5, timeout: 2} })
#@spam.redis_pool  => @redis_pool

list = SpamStreamResistance::WhiteBlackList.new(@redis_pool) # <=========

name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

#If you add keys in the black list but it doesn’t exist, the list has to be created and then keys have to be added to the list
list.add_in_black(name_of_list, keys)
 
#the next method checks if the blacklist exists   
list.black_list_exist?(name_of_list)

#we can check if the list includes the key
list.black_list_include?(name_of_list, keys[0]) #=> true
list.black_list_include?(name_of_list, keys[1]) #=>true

#the next method returns all keys from list
list.view_all_keys_from_black_list(name_of_list) #=> ["1@mail.com", "2@mail.com"]

#For deleting keys from the list we can use the following method
list.delete_keys_from_black_list(name_of_list, [ keys[1] ]) # => returns 1 if the key was deleted or 0 if the list doesn’t exist 


#check if the key exists in the list
list.black_list_include?(name_of_list, keys[1]) #=> false

#For deleting the blacklist we can use the following method
 list.delete_black_list(name_of_list) # => returns 1 if the list was deleted or 0 if the list doesn’t exist 

#We can check whether or not the blacklist exists by its name 
list.black_list_exist?(name_of_list) #=>  false
```



### Create a Whitelist 

```ruby
list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

#If you add keys in the whitelist but it doesn’t exist, the list has to be created and then keys have to be added to the list
list.add_in_white(name_of_list, keys)
    
#the next method checks if the whitelist exists   
list.white_list_exist?(name_of_list)

#we can check if the list includes the key
list.white_list_include?(name_of_list, keys[0]) #=> true
list.white_list_include?(name_of_list, keys[1]) #=> true

#the next method returns all keys from list
list.view_all_keys_from_white_list(name_of_list) #=> ["1@mail.com", "2@mail.com"]

#For deleting keys from the list we can use the following method
list.delete_keys_from_white_list(name_of_list, [ keys[1] ])

list.white_list_include?(name_of_list, keys[1]) #=> false

#For deleting the whitelist we can use the following method
list.delete_white_list(name_of_list)

#We can check whether or not the whitelist exists by its name 
list.white_list_exist?(name_of_list) == false
```



### Create your own list

```ruby
list = SpamStreamResistance::List.new(@redis_pool)

name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

#If you add keys in the list but it doesn’t exist, the list has to be created and then keys have to be added to the list
list.add_in_list(name_of_list, keys)
    
#the next method checks if the list exists   
list.list_exist?(name_of_list)

#we can check if the list includes the key
list.list_include?(name_of_list, keys[0]) #=> true
list.list_include?(name_of_list, keys[1]) #=> true

#the next method returns all keys from list
list.view_all_keys_from_list(name_of_list) #=> ["1@mail.com", "2@mail.com"]

#For deleting keys from the list we can use the following method
list.delete_keys_from_list(name_of_list, [ keys[1] ])

list.list_include?(name_of_list, keys[1]) #=> false

#For deleting the list we can use the following method
list.delete_list(name_of_list)

#We can check whether or not the list exists by its name 
list.list_exist?(name_of_list) == false
```



### Create the lifetime of a blacklist or a whitelist or your own list
 
#### Blacklist
```ruby
expire = 5 #lifetime in seconds  
    
list = SpamStreamResistance::WhiteBlackList.new(@redis_pool)

name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

list.add_in_black(name_of_list, keys)
    
list.black_list_exist?(name_of_list)

list.black_list_include?(name_of_list, keys[0])
list.black_list_include?(name_of_list, keys[1])

#set the lifetime of the list for 10 seconds
list.black_list_set_expire(name_of_list, 10)
    

#you can check the lifetime of the list
list.black_list_check_expire(name_of_list) #=> seconds

#you can delete the lifetime of the list
list.black_list_delete_expire(name_of_list)

#if the lifetime doesn’t exist the method returns -1
list.black_list_check_expire(name_of_list)# => -1
```

#### Whitelist 

```ruby
name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

list.add_in_white(name_of_list, keys)
    
list.white_list_exist?(name_of_list)

list.white_list_include?(name_of_list, keys[0])
list.white_list_include?(name_of_list, keys[1])

#set the lifetime of the list for 10 seconds
list.white_list_set_expire(name_of_list, 10)  #<======================
    
#you can check the lifetime of the list
list.white_list_check_expire(name_of_list) #=> seconds

#you can delete the lifetime of the list
list.white_list_delete_expire(name_of_list)

#if the lifetime doesn’t exist the method returns -1
list.white_list_check_expire(name_of_list) #=> -1
```

#### Your own list

```ruby
name_of_list = "list_1"
keys  = ["1@mail.com", "2@mail.com"]

list.add_in_list(name_of_list, keys)
    
list.list_exist?(name_of_list)

list.list_include?(name_of_list, keys[0])
list.list_include?(name_of_list, keys[1])

#set the lifetime of the list for 10 seconds
list.list_set_expire(name_of_list, 10)  #<======================
    
#you can check the lifetime of the list
list.list_check_expire(name_of_list) #=> seconds

#you can delete the lifetime of the list
list.list_delete_expire(name_of_list)

#if the lifetime doesn’t exist the method returns -1
list.list_check_expire(name_of_list) #=> -1
```

## Use Script Manager

**The same connections have the same functions**

```ruby
#Initialize 
redis_sett = {host: 'localhost', port: 6379}
connection_pool_sett = {size: 5, timeout: 2}

@redis_pool = ConnectionPool.new(connection_pool_sett) { Redis.new(redis_sett) }

@redis_scripts = SpamStreamResistance::RedisScripts.new(@redis_pool)

#the first lua script as a string
redis_lua_script_set_string_value = <<-EOF
      return redis.call('set', KEYS[1], KEYS[2])
  EOF
#the second lua script as a string
redis_lua_script_get_string_value = <<-EOF
      return redis.call('get', KEYS[1])
 EOF

#add scripts to the redis
added_scripts = @redis_scripts.add_scripts({set_string_value: redis_lua_script_set_string_value, get_string_value: redis_lua_script_get_string_value})

#for executing the script by its name
@redis_scripts.execute_script_by_name(:set_string_value, ["key_script_set_string", "value_script_set_string"])

#For getting  the list of scripts
list_of_scripts = @redis_scripts.list_of_scripts #=> ["set_string_value", "get_string_value"]

#check if the filter exists 
@redis_scripts.script_exists?(:set_string_value)#=> true
@redis_scripts.script_exists?(:set_string_value_1)#=>false

```





## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spam_stream_resistance'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spam_stream_resistance

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/spam_stream_resistance/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
