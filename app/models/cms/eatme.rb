class Cms::Eatme < Cms::Orm::Eatme
  key :name
  cms_acts_as_tree :counter_cache => :children_count
  cms_is_categorized
  cms_is_mirrored
  cms_has_revisions_for :blocks_attributes
  before_validation :assigns_label,
      :assign_parent
  after_save  :sync_child_pages
  before_create :assign_position
  before_save :assign_full_path,
              :set_cached_content



  def set_cached_content
  end
  # Forcing re-saves for child pages so they can update full_paths
  def sync_child_pages
    children.each{ |p| p.save! }
  end

  def assigns_label
    self.label = self.label.blank?? self.slug.try(:titleize) : self.label
  end

  def assign_parent
    return unless site
    self.parent ||= site.pages.roots.first unless self == site.pages.roots.first || site.pages.count == 0
  end

  def assign_full_path
    fp = self.parent ? "#{CGI::escape(self.parent.full_path).gsub('%2F', '/')}/#{self.slug}".squeeze('/') : '/'
    @full_path = fp if fp != @full_path
    @full_path = self.parent ? "#{CGI::escape(self.parent.full_path).gsub('%2F', '/')}/#{self.slug}".squeeze('/') : '/'
  end

  def assign_position
    return unless self.parent
    return if self.position.to_i > 0
    max = self.parent.children.reduce(0) { |m,l| m < l.position ? l.position : m }
    self.position = max ? max + 1 : 0
  end

end