class Cms::Orm::MongoMapper::Layout
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::ActsAsTree
  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


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

  #key :type, String, :null => false
  key :app_layout, String
  key :label, String, :null => false
  key :identifier, String, :null => false
  key :content, String
  key :css, String
  key :js, String
  key :position, Integer, :default => -1, :null => false
  key :is_shared, Boolean, :default => false, :null => false
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  many :pages, :class_name => "Cms::Page", :dependent => :nullify

  attr_accessible :app_layout, :label, :identifier, :content, :css, :js, :position, :is_shared
  attr_accessible :site, :site_id

  # -- Scopes ---------------------------------------------------------------
  #default_scope order(:position)
  # -- Class Methods --------------------------------------------------------
  # Tree-like structure for layouts
  def self.options_for_select(site, layout = nil, current_layout = nil, depth = 0, spacer = '. . ')
    out = []

    p current_layout
    [current_layout || site.layouts.roots.all].flatten.each do |l|
      p l
      next if layout == l
      out << [ "#{spacer*depth}#{l.label}", l.id ]
      l.children.all.each do |child|
        out += options_for_select(site, layout, child, depth + 1, spacer)
      end
    end
    return out.compact
  end

end