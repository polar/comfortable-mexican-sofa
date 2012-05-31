class CmsBaseController < ApplicationController

  # Thought this was supposed to be automatic, but it appears not.
  include ComfortableMexicanSofa::Engine.routes.url_helpers

end