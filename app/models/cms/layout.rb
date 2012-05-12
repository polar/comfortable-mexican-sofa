class Cms::Layout < Cms::Orm::Layout


  cms_acts_as_tree
  cms_is_mirrored
  cms_has_revisions_for :content, :css, :js

  # -- Callbacks ------------------------------------------------------------
  before_validation :assign_label
  before_create :assign_position
  after_save    :clear_cached_page_content
  after_destroy :clear_cached_page_content
  
  # -- Validations ----------------------------------------------------------
  validates :site_id,
    :presence   => true
  validates :label,
    :presence   => true
  validates :identifier,
    :presence   => true,
    :uniqueness => { :scope => :site_id },
    :format     => { :with => /^\w[a-z0-9_-]*$/i }


  # List of available application layouts
  def self.app_layouts_for_select
    Dir.glob(File.expand_path('app/views/layouts/**/*.html.*', Rails.root)).collect do |filename|
      filename.gsub!("#{File.expand_path('app/views/layouts', Rails.root)}/", '')
      filename.split('/').last[0...1] == '_' ? nil : filename.split('.').first
    end.compact.sort
  end
  
  # -- Instance Methods -----------------------------------------------------
  # magical merging tag is {cms:page:content} If parent layout has this tag
  # defined its content will be merged. If no such tag found, parent content
  # is ignored.
  def merged_content
    if parent
      regex = /\{\{\s*cms:page:content:?(?:(?::text)|(?::rich_text))?\s*\}\}/
      if parent.merged_content.match(regex)
        parent.merged_content.gsub(regex, content.to_s)
      else
        content.to_s
      end
    else
      content.to_s
    end
  end
  
protected
  
  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  # before create
  def assign_position
    #max = self.site.layouts.where(:parent_id => self.parent_id).all.reduce(0) { |m,l| m < l.position ? l.position : m }
    # Who knows why the fuck this doesn't work.
    #max = self.siblings.map(&:position).max
    max = Cms::Layout.where( :parent_id => self.parent_id).all.map(&:position).max
    self.position = max ? max + 1 : 0
  end
  
  # Forcing page content reload
  def clear_cached_page_content
    #if this happens as a result of an autosave in MongoMapper, it will not work because
    # the page will be invalid, trying to save the layout.
    #self.pages.each{ |page| page.save! }
    self.pages.each{ |page| page.reload }
    self.children.each{ |child_layout| child_layout.clear_cached_page_content }
  end
  
end
