class Cms::Orm::MongoMapper::File
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::IsCategorized

  include Paperclip::Glue

  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}

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

  cms_is_categorized :class_name => "Cms::File"

  attr_accessible :label, :file, :file_file_name, :file_content_type, :file_file_size, :description, :position
  attr_accessible :site, :site_id, :block, :block_id

  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_content_type.in => IMAGE_MIMETYPES)
  scope :not_images,  where(:file_content_type.nin =>  IMAGE_MIMETYPES)

  # -- Validations ----------------------------------------------------------
  validates :site_id, :presence => true
  validates_attachment_presence :file

  # -- Callbacks ------------------------------------------------------------
  before_save   :assign_label
  before_create :assign_position
  after_save    :reload_page_cache
  after_destroy :reload_page_cache

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

  attr_accessor :dimensions

  # -- AR Extensions --------------------------------------------------------
  has_attached_file :file, ComfortableMexicanSofa.config.upload_file_options.merge(
      # dimensions accessor needs to be set before file assignment for this to work
      :styles => lambda { |f|
        (f.instance.dimensions.blank?? { } : { :original => f.instance.dimensions }).merge(
            :cms_thumb => '80x60#'
        )
      }
  )
  before_post_process :is_image?

  # -- Instance Methods -----------------------------------------------------
  def is_image?
    IMAGE_MIMETYPES.include?(file_content_type)
  end

  protected

  # before_save   :assign_label
  def assign_label
    self.label = self.label.blank?? self.file_file_name.gsub(/\.[^\.]*?$/, '').titleize : self.label
  end

  # before_create :assign_position
  def assign_position
    max = Cms::File.all.map(&:position).max
    self.position = max ? max + 1 : 0
  end

  # after_save    :reload_page_cache
  # after_destroy :reload_page_cache
  # FIX: Terrible, but no way of creating cached page content otherwise
  def reload_page_cache
    return unless self.block
    p = self.block.page
    # TODO: This causes a save on the page, which calls a save on a File Block
    # which causes a save on the page, etc.
    Cms::Page.where(:id => p.id).all.each do |p|
      #p.update_attributes(:content_cache => p.content(true))
      p.content_dirty = true
      # p.save
    end
  end

end