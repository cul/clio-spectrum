# lib/tasks/append_stats_directories.rake
#
# 
# Adding our test-code directories to be reported by the command:
#   rake stats
# 
# Our labels are not really very usefully descriptive, but at least
# our code now gets counted.
# 
# Some docs suggested that this would fail in production due to missing
# rspec, but this seems to be working for us.

require 'rails/code_statistics'
::STATS_DIRECTORIES << %w(Controller\ Tests spec/controllers)
::STATS_DIRECTORIES << %w(Factories\ Tests spec/factories)
::STATS_DIRECTORIES << %w(Features\ Tests spec/features)
::STATS_DIRECTORIES << %w(Helpers\ Tests spec/helpers)
::STATS_DIRECTORIES << %w(Models\ Tests spec/models)
::STATS_DIRECTORIES << %w(Routing\ Tests spec/routing)
::STATS_DIRECTORIES << %w(Support\ Tests spec/support)
::STATS_DIRECTORIES << %w(Views\ Tests spec/views)
::CodeStatistics::TEST_TYPES << 'Controller Tests'
::CodeStatistics::TEST_TYPES << 'Factories Tests'
::CodeStatistics::TEST_TYPES << 'Features Tests'
::CodeStatistics::TEST_TYPES << 'Helpers Tests'
::CodeStatistics::TEST_TYPES << 'Models Tests'
::CodeStatistics::TEST_TYPES << 'Routing Tests'
::CodeStatistics::TEST_TYPES << 'Support Tests'
::CodeStatistics::TEST_TYPES << 'Views Tests'


