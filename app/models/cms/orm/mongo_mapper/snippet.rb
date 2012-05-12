class Cms::Orm::MongoMapper::Snippet
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  #create_table "cms_snippets", :force => true do |t|
  #  t.integer  "site_id",                                           :null => false
  #  t.string   "label",                                             :null => false
  #  t.string   "identifier",                                        :null => false
  #  t.text     "content",    :limit => 16777215
  #  t.integer  "position",                       :default => 0,     :null => false
  #  t.boolean  "is_shared",                      :default => false, :null => false
  #  t.datetime "created_at",                                        :null => false
  #  t.datetime "updated_at",                                        :null => false
  #end


  #key :type, String, :null => false
  key :label, String, :null => false
  key :identifier, String, :null => false
  key :content, String
  key :position, Integer, :default => -1, :null => false
  key :is_shared, Boolean, :default => false, :null => false
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"

  attr_accessible :label, :identifier, :content, :position, :is_shared
  attr_accessible :site, :site_id

  scope :by_position, order(:position)
end