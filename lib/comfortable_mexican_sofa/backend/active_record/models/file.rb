class Cms::Orm::ActiveRecord::File < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::IsCategorized

  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}

  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_files'

  attr_accessible :label, :file, :file_file_name, :file_content_type, :file_file_size, :description, :position
  attr_accessible :site, :site_id, :block, :block_id

  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :block, :class_name => "Cms::Block"

  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_content_type => IMAGE_MIMETYPES)
  scope :not_images,  where('file_content_type NOT IN (?)', IMAGE_MIMETYPES)

  cms_is_categorized

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
  before_post_process :set_file_content_type, :is_image?

  def set_file_content_type
    ct = MIME::Types.type_for(self.file_file_name).first
    ct ||= "undefined"
    self.file.instance_write(:content_type, ct.to_s)
  end

  # -- Validations ----------------------------------------------------------
  validates :site_id, :presence => true
  validates_attachment_presence :file

  # -- Callbacks ------------------------------------------------------------
  before_save   :assign_label
  before_create :assign_position
  after_save    :reload_page_cache
  after_destroy :reload_page_cache

  # -- Instance Methods -----------------------------------------------------
  def is_image?
    IMAGE_MIMETYPES.include?(file_content_type)
  end

  protected

  def assign_label
    self.label = self.label.blank?? self.file_file_name.gsub(/\.[^\.]*?$/, '').titleize : self.label
  end

  def assign_position
    max = Cms::File.all.map(&:position).max
    self.position = max ? max + 1 : 0
  end

  # FIX: Terrible, but no way of creating cached page content otherwise
  def reload_page_cache
    return unless self.block
    p = self.block.page
    # TODO: Analyze this. p.save causes a save on the page, which calls a save on a File Block
    # which causes a save on the page, etc.
    Cms::Page.where(:id => p.id).all.each do |p|
      #p.update_attributes(:content_cache => p.content(true))
      p.content_dirty = true
      # p.save
    end
  end

end
