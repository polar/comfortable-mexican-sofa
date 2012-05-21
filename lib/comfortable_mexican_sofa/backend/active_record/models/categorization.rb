class Cms::Orm::ActiveRecord::Categorization < ActiveRecord::Base

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_categorizations'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :category, :class_name => "Cms::Category"
  belongs_to :categorized, :class_name => "Cms::Categorization",
    :polymorphic => true

  # -- Validations ----------------------------------------------------------
  validates :categorized_type, :categorized_id,
            :presence   => true
  validates :category_id,
            :presence   => true,
            :uniqueness => { :scope => [:categorized_type, :categorized_id] }

end
