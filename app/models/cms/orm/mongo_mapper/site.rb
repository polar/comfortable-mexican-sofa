class Cms::Orm::MongoMapper::Site
  include MongoMapper::Document

  #create_table "cms_sites", :force => true do |t|
  #  t.string  "label",                          :null => false
  #  t.string  "identifier",                     :null => false
  #  t.string  "hostname",                       :null => false
  #  t.string  "path"
  #  t.string  "locale",      :default => "en",  :null => false
  #  t.boolean "is_mirrored", :default => false, :null => false
  #end

  key :label, String, :null => false
  key :identifier, String, :null => false
  key :hostname, String, :null => false
  key :path, String
  key :locale, String, :default => "en", :null => false
  key :is_mirrored, Boolean, :default => false, :null => false

  attr_accessible :label, :identifier, :hostname, :path, :locale, :is_mirrored

  # -- Relationships --------------------------------------------------------
  many :layouts,    :dependent => :delete_all
  many :pages,      :dependent => :delete_all
  many :snippets,   :dependent => :delete_all
  many :files,      :dependent => :destroy
  many :categories, :dependent => :delete_all

  # -- Scopes ---------------------------------------------------------------
  scope :mirrored, where(:is_mirrored => true)

end