module Cms
  module Orm
    class Page < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize
    end
  end
end