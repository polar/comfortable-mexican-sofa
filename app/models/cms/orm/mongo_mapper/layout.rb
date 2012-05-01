class Cms::Orm::MongoMapper::Layout
  include MongoMapper::Document

  #create_table "cms_layouts", :force => true do |t|
  #  t.integer  "site_id",                                           :null => false
  #  t.integer  "parent_id"
  #  t.string   "app_layout"
  #  t.string   "label",                                             :null => false
  #  t.string   "identifier",                                        :null => false
  #  t.text     "content",    :limit => 16777215
  #  t.text     "css",        :limit => 16777215
  #  t.text     "js",         :limit => 16777215
  #  t.integer  "position",                       :default => 0,     :null => false
  #  t.boolean  "is_shared",                      :default => false, :null => false
  #  t.datetime "created_at",                                        :null => false
  #  t.datetime "updated_at",                                        :null => false
  #end

  key :app_layout, String
  key :label, String, :null => false
  key :identifier, String, :null => false
  key :content, String
  key :css, String
  key :js, String
  key :position, Integer, :default => 0, :null => false
  key :is_shared, Boolean, :default => false, :null => false
  timestamps!

  belongs_to :site
  belongs_to :parent, :class_name => "Cms::Layout"

  many :pages

  # -- Scopes ---------------------------------------------------------------
  default_scope order(:position)
end