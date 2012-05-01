module Cms
  module Orm
    class Site < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Site".constantize
    end
  end
end