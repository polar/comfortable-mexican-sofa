require "rails/all"
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))

if  ComfortableMexicanSofa.config.backend.to_s == "active_record"
  require "active_record"
  require "comfortable_mexican_sofa/backend/active_record"
  if Rails.env == "test"
    require "machinist/active_record"
  end

  # This extension is needed so that arrays that seem like MongoMapper Associations
  # can be treated the same.
  class Array
    def all
      self
    end
  end
end