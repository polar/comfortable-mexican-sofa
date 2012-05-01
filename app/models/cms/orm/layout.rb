module Cms
  module Orm
    class Layout < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Layout".constantize
    end
  end
end