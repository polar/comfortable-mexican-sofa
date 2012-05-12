class Cms::Orm::MongoMapper::Category
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


#  self.table_name = 'cms_categories'
#  create_table "cms_categories", :force => true do |t|
#    t.integer "site_id",          :null => false
#    t.string  "label",            :null => false
#    t.string  "categorized_type", :null => false
#  end

  #key :type, String, :null => false
  key :label, String, :null => true
  key :categorized_type, String, :null => true

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  many :categorizations, :class_name => "Cms::Categorization",
           :dependent => :destroy

  attr_accessible :label, :categorized_type
  attr_accessible :site, :site_id

  # -- Scopes ---------------------------------------------------------------
  #default_scope order(:label)
  scope :of_type, lambda { |type|
    where(:categorized_type => type)
  }
end