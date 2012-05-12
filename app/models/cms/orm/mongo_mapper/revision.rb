class Cms::Orm::MongoMapper::Revision
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  #create_table "cms_revisions", :force => true do |t|
  #  t.string   "record_type",                     :null => false
  #  t.integer  "record_id",                       :null => false
  #  t.text     "data",        :limit => 16777215
  #  t.datetime "created_at"
  #end

  #key :type, String, :null => false
  key :data, String
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :record, :polymorphic => true

  attr_accessible :data
  attr_accessible :record, :record_id, :record_type

  scope :newest, order(:created_at.desc)
  # -- Scopes ---------------------------------------------------------------
  #default_scope order('created_at DESC')
  def self.query(options = {})
    p options
    super
  end
end