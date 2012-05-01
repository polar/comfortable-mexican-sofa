module Cms
  module Orm
    class Revision < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Revision".constantize
    end
  end
end