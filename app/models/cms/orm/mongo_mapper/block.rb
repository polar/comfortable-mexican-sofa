class Cms::Orm::MongoMapper::Block
  include MongoMapper::Document


  #create_table "cms_blocks", :force => true do |t|
  #  t.integer  "page_id",    :null => false
  #  t.string   "identifier", :null => false
  #  t.text     "content"
  #  t.datetime "created_at", :null => false
  #  t.datetime "updated_at", :null => false
  #end
  #self.table_name = 'cms_blocks'
  #
  ## -- Relationships --------------------------------------------------------
  #belongs_to :page
  #has_many :files,
  #         :autosave   => true,
  #         :dependent  => :destroy


  belongs_to :page
  many :files, :autosave => true, :dependent => :destroy   # maybe embedded.

  key :identifier, String, :null => false
  key :content, String,    :null => false
  timestamps!

  attr_accessible :page, :page_id, :identifier, :content
end