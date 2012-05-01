class Cms::Snippet < Cms::Orm::Snippet

  
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

  
protected
  
  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end
  
  # Note: This might be slow. We have no idea where the snippet is used, so
  # gotta reload every single page. Kinda sucks, but might be ok unless there
  # are hundreds of pages.
  def clear_cached_page_content
    site.pages.all.each do |p|
      Cms::Page.where(:id => p.id).update_all(:content => p.content(true))
    end
  end
  
  def assign_position
    max = self.site.snippets.maximum(:position)
    self.position = max ? max + 1 : 0
  end
  
end
