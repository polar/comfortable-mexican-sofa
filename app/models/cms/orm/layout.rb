module Cms
  module Orm
    class Layout < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Layout".constantize

      def save(*args)
        ret = super
        puts "Layout Save: #{self.inspect}"
        ret
      end
    end
  end
end