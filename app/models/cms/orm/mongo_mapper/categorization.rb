class Cms::Orm::MongoMapper::Categorization
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  #key :type, String, :null => false
#  self.table_name = 'cms_categorizations'

# -- Relationships --------------------------------------------------------
  belongs_to :category, :class_name => "Cms::Category"
  belongs_to :categorized, :class_name => "Cms::Categorization",
             :polymorphic => true

  # MongoMapper doesn't seem to create this until something is saved
  key :categorized_type
  #attr_accessor :categorized_type

  attr_accessible :category, :category_id
  attr_accessible :categorized, :categorized_id

  # -- Validations ----------------------------------------------------------
  validates :categorized_type, :categorized_id,
            :presence   => true
  validates :category_id,
            :presence   => true,
            :uniqueness => { :scope => [:categorized_type, :categorized_id] }

end