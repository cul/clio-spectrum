
# I didn't need to use this - but it might be handy
# at some point.

# # with_constants_v2
# # http://missingbit.blogspot.com/2011/07/stubbing-constants-in-rspec_20.html
# 
# # with_constants_v1
# # http://digitaldumptruck.jotabout.com/?p=551
# # "Every now and then, the need arises to stub the value of a Ruby
# # constant in your RSpec examples. The most obvious use case is to
# # test functionality in your Rails app that is environment-specific,
# # for instance a Rails action that should never be run in production."
# 
# 
# def parse_constant_v2(constant)
#   source, _, constant_name = constant.to_s.rpartition('::')
# 
#   [source.constantize, constant_name]
# end
# 
# def with_constants_v2(constants, &block)
#   saved_constants = {}
#   constants.each do |constant, val|
#     source_object, const_name = parse_constant_v2(constant)
# 
#     saved_constants[constant] = source_object.const_get(const_name)
#     Kernel::silence_warnings { source_object.const_set(const_name, val) }
#   end
# 
#   begin
#     block.call
#   ensure
#     constants.each do |constant, val|
#       source_object, const_name = parse(constant)
# 
#       Kernel::silence_warnings { source_object.const_set(const_name, saved_constants[constant]) }
#     end
#   end
# end
# 
# 
# 
# def with_constants_v1(constants, &block)
#   saved_constants = {}
#   constants.each do |constant, val|
#     saved_constants[ constant ] = Object.const_get( constant )
#     Kernel::silence_warnings { Object.const_set( constant, val ) }
#   end
#  
#   begin
#     block.call
#   ensure
#     constants.each do |constant, val|
#       Kernel::silence_warnings { 
#         Object.const_set( constant, saved_constants[ constant ] ) 
#       }
#     end
#   end
# end