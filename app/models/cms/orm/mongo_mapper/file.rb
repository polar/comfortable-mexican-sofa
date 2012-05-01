class Cms::Orm::MongoMapper::File
  include MongoMapper::Document

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

  key :label, String, :mull => false
  key :file_file_name, String, :mull => false
  key :file_content_type, String, :mull => false
  key :file_file_size, Integer, :mull => false
  key :description, String, :mull => false
  key :position, Integer, :mull => false
  timestamps!

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :required => true
  belongs_to :block

  attr_accessible :label, :file_file_name, :file_content_type, :file_file_size, :description, :position
  attr_accessible :site, :site_id, :block, :block_id

  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_content_type => IMAGE_MIMETYPES)
  scope :not_images,  where('file_content_type NOT IN (?)', IMAGE_MIMETYPES)
end