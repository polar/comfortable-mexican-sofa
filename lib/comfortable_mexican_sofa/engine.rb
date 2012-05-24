require 'comfortable_mexican_sofa'
require 'rails'
require 'paperclip'
require 'active_link_to'
require 'mime/types'

module ComfortableMexicanSofa
  class Engine < ::Rails::Engine

    # We get rid of running the initializers as an engine
    # as the ActiveRecord as default ORM will not start
    # if there isn't an ActiveRecord setup.
    config.paths["config/initializers"] = []
  end
end

