module ComfortableMexicanSofa::MongoMapper::IsCategorized
  
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    def cms_is_categorized
      include ComfortableMexicanSofa::MongoMapper::IsCategorized::InstanceMethods
      
      many :categorizations,
        :as         => :categorized,
        :class_name => 'Cms::Categorization',
        :dependent  => :destroy

      key :category_ids, Hash

      after_save :sync_categories
      
      scope :for_category, lambda { |*categories|
        if (categories = [categories].flatten.compact).present?
          # TODO: Fix for MongoMapper
          cats = Cms::Category.where(:label.in => categories).all
          catz = Cms::Categorization.where(:category_id.in => cats.map {|c|c.id}).all
          files = catz.select {|c| c.categorized_type == self.name }.map {|c|c.categorized}
          where(:id.in => files.map {|c|c.id})
        else
          #TODO: fix this, cannot be empty
          where()
        end
      }
    end
  end
  
  module InstanceMethods
    # Simulating has_many :through
    def categories
      categorizations.collect {|c| c.category }
    end

    def sync_categories
      (self.category_ids || {}).each do |category_id, flag|
        case flag.to_i
        when 1
          if category = Cms::Category.find_by_id(category_id)
            category.categorizations.create(:categorized => self)
          end
        when 0
          self.categorizations.where(:category_id => category_id).all.each { |c| c.destroy }
        end
      end
    end

    def presync_categories
      @category_ids = categorizations.collect {|c| c.category_id }
      @newcats = @category_ids - (@previous_category_ids||[])
      @oldcats = (@previous_category_ids||[]) - @category_ids
      @previous_category_ids = @category_ids
    end

  end
end