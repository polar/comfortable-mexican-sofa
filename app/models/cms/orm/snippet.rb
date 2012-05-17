module Cms
  module Orm
    class Snippet < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::Snippet".constantize
      def save(*args)
        ret = super
        puts "Snippet Save: #{self.inspect}"
        ret
      end
    end
  end
end