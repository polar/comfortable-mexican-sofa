module Cms
  module Orm
    class Eatme < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Eatme".constantize
      def self.after_find(*args)

      end

      def save(*args)
        puts "Eatme.save #{self.inspect}"
        super
      end
    end
  end
end