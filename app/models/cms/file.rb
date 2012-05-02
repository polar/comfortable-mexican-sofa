class Cms::File < Cms::Orm::File
  
  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}

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
  before_post_process :is_image?

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
    max = Cms::File.maximum(:position)
    self.position = max ? max + 1 : 0
  end
  
  # FIX: Terrible, but no way of creating cached page content overwise
  def reload_page_cache
    return unless self.block
    p = self.block.page
    Cms::Page.where(:id => p.id).update_all(:content => p.content(true))
  end
  
end
