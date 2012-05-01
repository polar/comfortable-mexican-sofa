module Cms
  module Orm
    class Block < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Block".constantize
    end
  end
end

