class Cms::Orm::ActiveRecord::Category < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_categories'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  has_many :categorizations, :class_name => "Cms::Categorization",
    :dependent => :destroy

  # -- Scopes ---------------------------------------------------------------
  default_scope order(:label)
  scope :of_type, lambda { |type|
    where(:categorized_type => type)
  }
  
end
