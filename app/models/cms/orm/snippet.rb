module Cms
  module Orm
    class Snippet < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Snippet".constantize
    end
  end
end