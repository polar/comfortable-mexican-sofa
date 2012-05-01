class Cms::Orm::MongoMapper::Page
  include MongoMapper::Document

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

  key :label, String, :null => false
  key :slug, String
  key :full_path, String, :null => false
  key :content
  key :position, Integer, :default => 0, :null => false
  key :children_count, Integer, :default => 0, :null => false
  key :is_published, Boolean, :default => true, :null => false
  key :is_shared, Boolean, :default => false, :null => false

  belongs_to :site
  belongs_to :layout
  belongs_to :parent, :class_name => "Cms::Page"
  belongs_to :target_page, :class_name => "Cms::Page"

  many :blocks,
           :autosave   => true,
           :dependent  => :destroy

  attr_accessible :label, :slug, :full_path, :content, :position, :children_count, :is_published, :is_shared
  attr_accessible :site, :site_id
  attr_accessible :layout, :layout_id
  attr_accessible :parent, :parent_id
  attr_accessible :target_page, :target_page_id

  # -- Scopes ---------------------------------------------------------------
  default_scope order(:position)
  scope :published, where(:is_published => true)

end