class Cms::Orm::MongoMapper::Revision
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :data, Hash
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :record, :polymorphic => true

  attr_accessible :data
  attr_accessible :record, :record_id, :record_type

  scope :newest, order(:created_at.desc)
  # -- Scopes ---------------------------------------------------------------
  #default_scope order('created_at DESC')
end