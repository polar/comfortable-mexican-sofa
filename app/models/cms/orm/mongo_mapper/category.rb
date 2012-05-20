class Cms::Orm::MongoMapper::Category
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

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

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            :presence   => true
  validates :label,
            :presence   => true,
            :uniqueness => { :scope => [:categorized_type, :site_id] }
  validates :categorized_type,
            :presence   => true

end