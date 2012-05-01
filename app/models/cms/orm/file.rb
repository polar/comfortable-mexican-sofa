module Cms
  module Orm
    class File < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::File".constantize
    end
  end
end