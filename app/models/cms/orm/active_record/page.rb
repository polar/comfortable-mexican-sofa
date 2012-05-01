# encoding: utf-8
class Cms::Orm::ActiveRecord::Page < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)

  cms_acts_as_tree :counter_cache => :children_count
  cms_is_categorized
  cms_is_mirrored
  cms_has_revisions_for :blocks_attributes

  attr_accessor :tags,
                :blocks_attributes_changed

  self.table_name = 'cms_pages'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :site
  belongs_to :layout
  belongs_to :target_page,
    :class_name => 'Cms::Page'
  has_many :blocks,
    :autosave   => true,
    :dependent  => :destroy


  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_pages.position')
  scope :published, where(:is_published => true)

end
