module Cms
  module Orm
    class Block < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Block".constantize
      puts "Loading Cms::Orm::Block from #{self.superclass.name}"
      def initialize(*args)
        puts "New Block #{self} #{args.inspect}"
        super
      end

      def save(*args)
        puts "Saving Block #{self} #{self.content.inspect} #{self.page.tags if self.page}"
        ret = super
        puts "---Saved #{ret} #{content.inspect}"
        if !ret
          p self.errors
        end
        ret
      end

      def reload(*args)
        puts "Reloading Block"
        ret = super
        puts "Reloaded Block"
        return ret
      end
    end
  end
end

