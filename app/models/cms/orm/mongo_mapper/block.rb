class Cms::Orm::MongoMapper::Block
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  # -- Relationships --------------------------------------------------------
  belongs_to :page, :class_name => "Cms::Page"
  many :files, :class_name => "Cms::File",
           :autosave           => true,
           :dependent          => :destroy

  key :identifier, String, :null => false
  key :content_value
  timestamps!

  attr_accessor :content_files

  attr_accessible :page, :page_id, :identifier, :content

  # -- Callbacks ------------------------------------------------------------
  before_save :prepare_files

  # ActiveRecord has mark_for_destruction on has_many associations
  # that destroys the item on the next save. It only applies to
  # associations with :autosave options. We mimic it here using
  # an after_save callback. And putting mark_for_destruction and
  # marked_for_destruction? methods on file.rb
  after_save :eliminate_marked_files

  # -- Instance Methods -----------------------------------------------------
  # Tag object that is using this block
  def tag
    @tag ||= page.tags(true).detect{|t| t.is_cms_block? && t.identifier == identifier}
  end

  # after_save :eliminate_marked_files
  def eliminate_marked_files
    files.each do |f|
      if f.marked_for_destruction?
        f.destroy
      end
    end
  end

  # Active Record allows the attribute not to be its type before
  # saving. However, MongoMapper converts to its type.
  # A type system, imagine that?!?!
  # If the value is a string, we store it. If it is not a string
  # it will not last long, as prepare_files will change them
  # into files an null the content after that.
  def content=(value)
    @content_was = content
    @content_files = nil
    @content_files_dirty = false
    if value.is_a?(String) || value.is_a?(BSON::ObjectId)
      self.content_value = value.to_s
      puts "WTF?"
    else
      @content_files = value # these should be file types or an array of file types
      self.content_value = nil
      @content_files_dirty = true  # if content_value was nil before it content_change? will still be false.
    end
  end

  def content_changed?
    content_value_changed?  || @content_files_dirty
  end

  def content_was
     content_value_was
  end

  def content
    @content_files || @content_value
  end

protected

  def prepare_files
    #on a create the page_id is set, but not the association for page
    if page.nil? && page_id
      @_page = Cms::Page.find(page_id)
    end
    puts "Block.prepare_files #{content.inspect} #{tag} #{page.tags(true)}"
    temp_files = [@content_files].flatten.select do |f|
      %w(ActionDispatch::Http::UploadedFile Rack::Test::UploadedFile).member?(f.class.name)
    end

    # only accepting one file if it's PageFile. PageFiles will take all
    single_file = self.tag.is_a?(ComfortableMexicanSofa::Tag::PageFile)
    temp_files = [temp_files.first].compact if single_file

    temp_files.each do |file|
      self.files.collect{|f| f.mark_for_destruction } if single_file
      self.files.build(:site => self.page.site, :dimensions => self.tag.try(:dimensions), :file => file)
    end

    self.content = nil unless self.content.is_a?(String)
  end
end