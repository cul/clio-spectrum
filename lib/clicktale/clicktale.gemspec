$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "clicktale"
  s.version     = '0.1'
  s.authors     = ["Stuart Marquis"]
  s.email       = ["stuartmarquis@gmail.com"]
  s.homepage    = "http://example.com"
  s.summary     = "Clicktale integration"
  # s.description = "Clicktale integration"

  s.files = Dir["{app,config,lib}/**/*"]
  # s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.16"
  # s.add_dependency "jquery-rails"

  # s.add_development_dependency "sqlite3"
end
