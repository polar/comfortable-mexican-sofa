require "rails/all"
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))
require File.expand_path("cms_mongodb", File.dirname(__FILE__))

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  require "mongo_mapper"
  if Rails.env == "test"
    require "machinist/mongo_mapper"
  end
end