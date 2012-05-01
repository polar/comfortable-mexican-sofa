class Cms::Orm::ActiveRecord::File < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  cms_is_categorized

  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}
  
  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_files'

  # -- Relationships --------------------------------------------------------
  belongs_to :site
  belongs_to :block

  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_content_type => IMAGE_MIMETYPES)
  scope :not_images,  where('file_content_type NOT IN (?)', IMAGE_MIMETYPES)
end
