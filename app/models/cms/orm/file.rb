module Cms
  module Orm
    class File < "Cms::Orm::#{ComfortableMexicanSofa.config.backend.to_s.classify}::File".constantize
      def save(*args)
        puts "File.save #{self.inspect}"
        super
      end
    end
  end
end