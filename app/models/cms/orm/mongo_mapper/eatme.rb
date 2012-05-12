class Cms::Orm::MongoMapper::Eatme
  include MongoMapper::Document

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  key :label, String, :null => false
  key :slug, String
  key :full_path, String, :null => false
  #TODO: Change this in AR
  key :content_dirty, Boolean, :default => true
  key :content_cache, String
  key :position, Integer, :default => 0, :null => false
  key :is_published, Boolean, :default => true, :null => false
  key :is_shared, Boolean, :default => false, :null => false

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :layout, :class_name => "Cms::Layout"
  belongs_to :target_page, :class_name => 'Cms::Page'
  many :blocks, :class_name => "Cms::Block",
       :autosave   => true,
       :dependent  => :destroy

  attr_accessible :full_path
  attr_accessible :label, :slug, :content, :position, :children_count, :is_published, :is_shared
  attr_accessible :site, :site_id
  attr_accessible :layout, :layout_id
  attr_accessible :parent, :parent_id
  attr_accessible :target_page, :target_page_id
  attr_accessible :shit, :shit_id

  # -- Scopes ---------------------------------------------------------------
  #default_scope order(:position)
  scope :published, where(:is_published => true)

  attr_accessible :blocks_attributes
  attr_accessor :tags,
                :blocks_attributes_changed
end