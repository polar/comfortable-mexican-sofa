source 'http://rubygems.org'

gem 'rails',          '>= 3.0.0'
gem 'active_link_to', '~> 1.0.0'

if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9.2')
  gem 'paperclip', '>= 2.3.0', '< 3.0.0'
else
  gem 'paperclip', '>= 2.3.0'
end

group :development do
  gem 'linecache19', '0.5.13'
  gem 'ruby-debug-base19x', '0.11.30.pre10'
  gem 'ruby-debug-ide'
end

group "mongo_mapper" do
  gem 'bson_ext'
  gem 'mongo_mapper'
end

group "test" do
  gem "test-unit"
  gem 'sqlite3'
  gem 'jeweler'

  gem 'database_cleaner'
  gem "machinist_mongo", :git => "git://github.com/polar/machinist_mongo.git", :branch => "master"
end
