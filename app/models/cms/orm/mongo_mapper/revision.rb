class Cms::Orm::MongoMapper::Revision
  include MongoMapper::Document

  #create_table "cms_revisions", :force => true do |t|
  #  t.string   "record_type",                     :null => false
  #  t.integer  "record_id",                       :null => false
  #  t.text     "data",        :limit => 16777215
  #  t.datetime "created_at"
  #end

  key :data, String
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :record, :polymorphic => true

  attr_accessible :data
  attr_accessible :record, :record_id, :record_type

  scope :newest, order(:created_at.desc)
  # -- Scopes ---------------------------------------------------------------
  default_scope order('created_at DESC')
end