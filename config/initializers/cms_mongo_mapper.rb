require "rails/all"
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))
require File.expand_path("cms_mongodb", File.dirname(__FILE__))

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  require "mongo_mapper"

  # The Machinist Plugin must be loaded *before* the models are loaded, as the
  # plugin extends MongoMapper::Document and EmbeddedDocument modules. Extending
  # modules after they are included has no affect.
  if Rails.env == "test"
    require "machinist/mongo_mapper"
  end
  # Loads the MongoMapper based models and extensions.
  require "comfortable_mexican_sofa/backend/mongo_mapper"
end