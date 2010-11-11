class Object
  # lets you use  "a".in?(alphabet) instead of alphabet.include?("a")
  # pure syntactic sugar, but we're diabetics over here.
  def in?(*args)
    collection = (args.length == 1 ? args.first : args)
    collection ? collection.include?(self) : false 
  end
  
  alias_method :one_of?, :in?
  
  
  def listify(opts = {})
    case self
    when NilClass
      opts[:include_nil] ? [nil] : []
    when Array
      self
    else
      [self]
    end
      
  end

  # returns a sorted list of methods that are unique to an object compared to some other object
  # compares to Object by default
  def interesting_methods(compare_to = Object)
    compare_to = compare_to.class unless compare_to.kind_of?(Class)
    (self.methods - compare_to.new.methods).sort
  end
end

class String
  # abbreviates strings to a fixed width, replacing the last few characters with padding
  # "this is very very long".abbreviate(15, "...") => "this is very..."  
  # "this is short".abbreviate(15, "...") => "this is short"
  def abbreviate(characters, padding = "...")
    if length > characters
      self[0,characters - padding.length] + padding
    else
      self
    end
  end
end


module Enumerable
  # checks to see if any of the values in the enumerable are in 
  # [3,2,4].any_in?(6,1,2) => true
  # [3,2,4].any_in?(5,6,7) => false
  def any_in?(*args)
    self.any? { |value| args.include?(value)}
  end
end

class Hash
  # creates a hash of arbitrary depth: you can refer to nested hashes without initialization.
  def self.arbitrary_depth
    Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
  end
  
  def recursive_symbolize_keys!
    symbolize_keys!
    values.select{|v| v.is_a? Hash}.each{|h| h.recursive_symbolize_keys!}
    self
  end
  
end


