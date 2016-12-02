class Object
  # lets you use  "a".in?(alphabet) instead of alphabet.include?("a")
  # pure syntactic sugar, but we're diabetics over here.
  def in?(*args)
    return false if self.nil?
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
    (methods - compare_to.new.methods).sort
  end
end

class String
  # abbreviates strings to a fixed width, replacing the last few characters with padding
  # "this is very very long".abbreviate(15, "...") => "this is very..."
  # "this is short".abbreviate(15, "...") => "this is short"
  def abbreviate(characters, padding = '...')
    if length > characters
      self[0, characters - padding.length] + padding
    else
      self
    end
  end
end

class DateTime
  def to_solr_s
    to_s.gsub('+00:00', 'Z')
  end
end

# module Enumerable
#   # checks to see if any of the values in the enumerable are in
#   # [3,2,4].any_in?(6,1,2) => true
#   # [3,2,4].any_in?(5,6,7) => false
#   def any_in?(*args)
#     self.any? { |value| args.include?(value) }
#   end
# end

class Hash
  # creates a hash of arbitrary depth: you can refer to nested hashes without initialization.
  def self.arbitrary_depth
    Hash.new(&(p=lambda{|h, k| h[k] = Hash.new(&p)}))
  end

  # def recursive_symbolize_keys!
  #   symbolize_keys!
  #   values.select { |v| v.is_a? Hash }.each { |h| h.recursive_symbolize_keys! }
  #   self
  # end

  def deep_clone
    Marshal.load(Marshal.dump(self))
  end

  def recursive_merge(hash = nil)
    return self unless hash.is_a?(Hash)
    base = self
    hash.each do |key, v|
      if base[key].is_a?(Hash) && hash[key].is_a?(Hash)
        base[key].recursive_merge(hash[key])
      else
        base[key] = hash[key]
      end
    end
    base
  end
end

# class ActiveSupport::Cache::MemoryStore
class ActiveSupport::Cache::Store

  def clio_key_count
    return @data.keys.size if defined? @data
    'unknown'
  end

  def clio_cache_size
    return @cache_size.to_s(:human_size) if defined? @cache_size
    return self.stats['used_memory_human'] if self.respond_to?(:stats)
    'unknown'
  end
end

# # This is in Rails 4.1, 4.2, and onward.
# # Add it here as a monkey-patch for Rails 4.0,
# # *** try to remember to remove this after Rails upgrade ***
# # https://github.com/rails/rails/pull/19941
# module ActionView
#   module Helpers
#     module CacheHelper
# 
#       def cache(name = {}, options = nil, &block)
#         if controller.respond_to?(:perform_caching) && controller.perform_caching
#           safe_concat(fragment_for(cache_fragment_name(name, options), options, &block))
#         else
#           yield
#         end
# 
#         nil
#       end
#     end
#   end
# end

# Some monkey patching to add some network debugging

# module Net
#   class HTTP
#     def do_start
#       # DEBUGGING
#       # puts "#{Time.now} [Net::HTTP#do_start]  opening connection to #{address.to_s}:#{port.to_s}..."
#       connect
#       @started = true
#     end
#   end
# end



# class RSolr::Connection
#   def http uri, proxy = nil, read_timeout = nil, open_timeout = nil
#     @http ||= (
#       http = if proxy
#         proxy_user, proxy_pass = proxy.userinfo.split(/:/) if proxy.userinfo
#         Net::HTTP.Proxy(proxy.host, proxy.port, proxy_user, proxy_pass).new uri.host, uri.port
#       else
#         Net::HTTP.new uri.host, uri.port
#       end
#       http.use_ssl = uri.port == 443 || uri.instance_of?(URI::HTTPS)
#       http.read_timeout = read_timeout if read_timeout
#       http.open_timeout = open_timeout if open_timeout
# 
#       # TURN ON DEBUGGING
#       http.set_debug_output $stderr
# 
#       http
#     )
#   end
# end

class Traject::DebugWriter
  def serialize(context)
    h       = context.output_hash
    rec_key = record_number(context)
    # lines   = h.keys.sort.map { |k| @format % [rec_key, k, h[k].join(' | ')] }
    lines   = h.keys.sort.map { |k|
      Array(h[k]).map { |v|
        @format % [rec_key, k, v]
      }
    }
    lines.push "\n"
    lines.join("\n")
  end
end

module Traject::Macros
  module Marc21
    def self.trim_trailing_period(str)
      # str = str.sub(/(.+\w\w)\. *\Z/, '\1')
      # str = str.sub(/(.+\p{L}\p{L})\. *\Z/, '\1')
      str = str.sub(/(.+\p{Alnum}\p{M}?\p{Alnum}\p{M}?)\. *\Z/, '\1')
      str = str.sub(/(.+\p{Punct})\. *\Z/, '\1')
      return str
    end

    def self.trim_punctuation(str)
      # If something went wrong and we got a nil, just return it
      return str unless str

      # trailing: comma, slash, semicolon, colon (possibly preceded and followed by whitespace)
      str = str.sub(/ *[ ,\/;:] *\Z/, '')

      # trailing period if it is preceded by at least three letters (possibly preceded and followed by whitespace)
      # str = str.sub(/( *\w\w\w)\. *\Z/, '\1')
      str = trim_trailing_period(str)

      # single square bracket characters if they are the start and/or end
      #   chars and there are no internal square brackets.
      str = str.sub(/\A\[?([^\[\]]+)\]?\Z/, '\1')

      # trim any leading or trailing whitespace
      str.strip!

      return str
    end
  end
end

# # Override for debugging... 
# module MARC
#   class Reader
# 
#     def each_raw
#       unless block_given?
#         return self.enum_for(:each_raw)
#       else
#         while rec_length_s = @handle.read(5)
#           # make sure the record length looks like an integer
#           rec_length_i = rec_length_s.to_i
#           if rec_length_i == 0
#             puts "rec_length_s=[#{rec_length_s}]"
#             puts "rec_length_s.length=[#{rec_length_s.length}]"
# 
#             puts "rec_length_s[0]=[#{rec_length_s[0]}]"
#             puts "rec_length_s[1]=[#{rec_length_s[1]}]"
#             puts "rec_length_s[2]=[#{rec_length_s[2]}]"
#             puts "rec_length_s[3]=[#{rec_length_s[3]}]"
#             puts "rec_length_s[4]=[#{rec_length_s[4]}]"
# 
#             puts "rec_length_s.bytes.inspect=[#{rec_length_s.bytes.inspect}]"
# 
#             puts "rec_length_i=[#{rec_length_i}]"
#             puts "@handle.eof?=[#{@handle.eof?}]"
#             raise MARC::Exception.new("invalid record length: #{rec_length_s}")
#           end
# 
#           # get the raw MARC21 for a record back from the file
#           # using the record length
#           raw = rec_length_s + @handle.read(rec_length_i-5)
#           yield raw
#         end
#       end
#     end
# 
#   end
# end


