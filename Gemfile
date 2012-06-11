source 'http://rubygems.org'

gem 'rails', '3.1.3'
gem 'jquery-rails'

gem 'haml', '~> 3.0'
gem 'haml-rails'

gem 'bilge-pump',
  git: 'git://github.com/flipstone/bilge-pump.git',
  branch: '3390d04'

gem 'mongo', '1.3.1'
gem 'bson', '1.3.1'
gem 'bson_ext', '1.3.1'
gem 'mongo_mapper', '0.9.2'
gem 'mongo_session_store', require: 'mongo_session_store/mongo_mapper'

gem 'zbatery'
gem 'capistrano', '~> 2.5'
gem 'flipstone-deployment', git: 'git://github.com/flipstone/flipstone-deployment.git', branch: '332bbbe'

gem "pivotal-tracker", "~> 0.5.1"

gem 'flipstone-charts', git: "git://github.com/flipstone/flipstone-charts", branch: "6ea3409"

gem "will_paginate", "~> 3.0.3"


group :assets do
  gem 'haml_coffee_assets'
  gem 'execjs'
  gem 'therubyracer'
  gem 'sass-rails'
  gem 'uglifier'
  gem "coffee-rails", "~> 3.1.1"
end

group :test, :development, :cruise do
  # Pretty printed test output
  gem 'turn', '0.8.2', :require => false
  gem 'rspec'
  gem 'rspec-rails'
  gem 'factory_girl'
  gem 'factory_girl_rails'
  gem 'jasmine', '1.2.0.rc2',
    git: "git://github.com/pivotal/jasmine-gem.git",
    branch: "953d17dff4b4adba79b2a808b55cf33f4ff93af7"

  gem 'jasmine-phantom', '>= 0.0.2'
  gem 'rack-asset-compiler'
end

gem 'backbone-on-rails'