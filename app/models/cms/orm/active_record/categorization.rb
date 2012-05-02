class Cms::Orm::ActiveRecord::Categorization < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_categorizations'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :category, :class_name => "Cms::Category"
  belongs_to :categorized, :class_name => "Cms::Categorization",
    :polymorphic => true
  
end
