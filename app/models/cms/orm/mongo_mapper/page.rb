class Cms::Orm::MongoMapper::Page
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  #create_table "cms_pages", :force => true do |t|
  #  t.integer  "site_id",                                               :null => false
  #  t.integer  "layout_id"
  #  t.integer  "parent_id"
  #  t.integer  "target_page_id"
  #  t.string   "label",                                                 :null => false
  #  t.string   "slug"
  #  t.string   "full_path",                                             :null => false
  #  t.text     "content",        :limit => 16777215
  #  t.integer  "position",                           :default => 0,     :null => false
  #  t.integer  "children_count",                     :default => 0,     :null => false
  #  t.boolean  "is_published",                       :default => true,  :null => false
  #  t.boolean  "is_shared",                          :default => false, :null => false
  #  t.datetime "created_at",                                            :null => false
  #  t.datetime "updated_at",                                            :null => false
  #end

  #key :type, String, :null => false
  key :label, String, :null => false
  key :slug, String
  key :escaped_slug, String
  key :escaped_full_path, String, :null => false
  #TODO: Change this in AR
  key :content_dirty, Boolean, :default => true
  key :content_cache, String
  key :position, Integer, :default => -1, :null => false
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

  # Transforms existing cms_block information into a hash that can be used
  # during form processing. That's the only way to modify cms_blocks.
  def blocks_attributes(was = false)
    self.blocks.all.collect do |block|
        block_attr = {}
        block_attr[:identifier] = block.identifier
        block_attr[:content]    = was ? block.content_was : block.content
        block_attr
    end
  end

  # Array of block hashes in the following format:
  #   [
  #     { :identifier => 'block_1', :content => 'block content' },
  #     { :identifier => 'block_2', :content => 'block content' }
  #   ]
  def blocks_attributes=(block_hashes = [])
    block_hashes = block_hashes.values if block_hashes.is_a?(Hash)
    block_hashes.each do |block_hash|
      block_hash.symbolize_keys! unless block_hash.is_a?(HashWithIndifferentAccess)
      block =
          self.blocks.all.detect{|b| b.identifier == block_hash[:identifier]} ||
              self.blocks.build(:identifier => block_hash[:identifier])
      block.content = block_hash[:content]
      self.blocks_attributes_changed = self.blocks_attributes_changed || block.content_changed?
    end
  end

end