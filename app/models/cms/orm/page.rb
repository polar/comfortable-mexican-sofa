module Cms
  module Orm
    class Page < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize
      def self.after_find(*args)

      end
      def save(*args)
        puts "Page.save #{self.inspect}"
        ret = super

        puts "Page.blocks #{self.blocks.count} #{self.blocks.size}"
        return ret
      end
    end
  end
end