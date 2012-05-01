module Cms
  module Orm
    class Categorization < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Categorization".constantize
    end
  end
end