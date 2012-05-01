class Cms::Orm::MongoMapper::Category
  include MongoMapper::Document

#  self.table_name = 'cms_categories'
#  create_table "cms_categories", :force => true do |t|
#    t.integer "site_id",          :null => false
#    t.string  "label",            :null => false
#    t.string  "categorized_type", :null => false
#  end

  key :label, String, :null => true
  key :categorized_type, String, :null => true

  belongs_to :site, :required => true
  many :categorizations, :required => true, :dependent => :destroy    # embedded?

  attr_accessible :label, categorized_type
  attr_accessbile :site, :site_id

  # -- Scopes ---------------------------------------------------------------
  default_scope order(:label)
  scope :of_type, lambda { |type|
    where(:categorized_type => type)
  }
end