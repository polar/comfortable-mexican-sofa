module Cms
  module Orm
    class Page < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Page".constantize
      def self.after_find(*args)

      end
      def save(*args)
        ret = super
        puts "Page.save #{self.inspect}"

        puts "Page.blocks #{self.blocks.count} #{self.blocks.size}"
        return ret
      end

      def destroy(*args)
        puts "Page.destroy before #{id}"
        ret = super
        puts "Page.destroy after #{id}"
      end

    end
  end
end