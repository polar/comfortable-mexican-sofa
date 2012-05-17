require "rails/all"
require File.expand_path("comfortable_mexican_sofa", File.dirname(__FILE__))

if  ComfortableMexicanSofa.config.backend.to_s == "active_record"
  require "active_record"
  if Rails.env == "test"
    require "machinist/active_record"
  end
end