class Cms::Orm::MongoMapper::File
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored

  include Paperclip::Glue

  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}

  #create_table "cms_files", :force => true do |t|
  #  t.integer  "site_id",                                          :null => false
  #  t.integer  "block_id"
  #  t.string   "label",                                            :null => false
  #  t.string   "file_file_name",                                   :null => false
  #  t.string   "file_content_type",                                :null => false
  #  t.integer  "file_file_size",                                   :null => false
  #  t.string   "description",       :limit => 2048
  #  t.integer  "position",                          :default => 0, :null => false
  #  t.datetime "created_at",                                       :null => false
  #  t.datetime "updated_at",                                       :null => false
  #end

  #key :type, String, :null => false
  key :label, String, :mull => false
  key :file_file_name, String, :mull => false
  key :file_content_type, String, :mull => false
  key :file_file_size, Integer, :mull => false
  key :description, String, :mull => false
  key :position, Integer, :default => -1, :mull => false
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :block, :class_name => "Cms::Block"


  attr_accessible :label, :file, :file_file_name, :file_content_type, :file_file_size, :description, :position
  attr_accessible :site, :site_id, :block, :block_id

  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_content_type => IMAGE_MIMETYPES)
  scope :not_images,  where(:file_content_type.nin() =>  IMAGE_MIMETYPES)

  # ActiveRecord has mark_for_destruction on has_many associations
  # that destroys the item on the next save. It only applies to
  # associations with :autosave options. We mimic it here using
  # an after_save callback in block.rb. And putting mark_for_destruction and
  # marked_for_destruction? methods here in file.rb

  def mark_for_destruction
    @mark_for_destruction = true
  end

  def marked_for_destruction?
    @mark_for_destruction
  end
end