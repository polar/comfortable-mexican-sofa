module Cms
  module Orm
    class Category < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Category".constantize
    end
  end
end