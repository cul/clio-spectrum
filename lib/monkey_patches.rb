class Object
  # Not needed - Rails already has .in()
  # # lets you use  "a".in?(alphabet) instead of alphabet.include?("a")
  # # pure syntactic sugar, but we're diabetics over here.
  # def in?(*args)
  #   return false if nil?
  #   collection = (args.length == 1 ? args.first : args)
  #   collection ? collection.include?(self) : false
  # end

  # alias_method :one_of?, :in?

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

end

# Fully redundant with Ruby String.truncate()
# class String
#   # abbreviates strings to a fixed width, replacing the last few characters with padding
#   # "this is very very long".abbreviate(15, "...") => "this is very..."
#   # "this is short".abbreviate(15, "...") => "this is short"
#   def abbreviate(characters, padding = '...')
#     if length > characters
#       self[0, characters - padding.length] + padding
#     else
#       self
#     end
#   end
# end

# class Hash
#   # Unnecessary
#   # # creates a hash of arbitrary depth: you can refer to nested hashes without initialization.
#   # def self.arbitrary_depth
#   #   Hash.new(&(p = ->(h, k) { h[k] = Hash.new(&p) }))
#   # end
#
#   # Replace with .deep_dup
#   # def deep_clone
#   #   Marshal.load(Marshal.dump(self))
#   # end
#
#   # Replace with .deep_merge()
#   # def recursive_merge(hash = nil)
#   #   return self unless hash.is_a?(Hash)
#   #   base = self
#   #   hash.each do |key, _v|
#   #     if base[key].is_a?(Hash) && hash[key].is_a?(Hash)
#   #       base[key].recursive_merge(hash[key])
#   #     else
#   #       base[key] = hash[key]
#   #     end
#   #   end
#   #   base
#   # end
# end

# Override default logging format via monkey patch,
# (instead of writing & using new custom class)
class Logger
  def format_message(severity, timestamp, _program, message)
    "#{timestamp.to_formatted_s(:db)} [#{severity}] #{message}\n"
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
    return stats['used_memory_human'] if respond_to?(:stats)
    'unknown'
  end
end


# Some monkey patching to add some network debugging

class Traject::DebugWriter
  def serialize(context)
    h       = context.output_hash
    rec_key = record_number(context)
    # lines   = h.keys.sort.map { |k| @format % [rec_key, k, h[k].join(' | ')] }
    lines   = h.keys.sort.map do |k|
      Array(h[k]).map do |v|
        @format % [rec_key, k, v]
      end
    end
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
      str
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

      str
    end
  end
end
