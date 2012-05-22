class Cms::Orm::ActiveRecord::Category < ActiveRecord::Base

  ComfortableMexicanSofa.establish_connection(self)
  
  self.table_name = 'cms_categories'

  attr_accessible :label, :categorized_type
  attr_accessible :site, :site_id

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  has_many :categorizations, :class_name => "Cms::Categorization",
    :dependent => :destroy

  # -- Scopes ---------------------------------------------------------------
  default_scope order(:label)
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
