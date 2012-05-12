class Cms::Block < Cms::Orm::Block

  # -- Callbacks ------------------------------------------------------------
  before_save :prepare_files
  
  # -- Validations ----------------------------------------------------------
  validates :identifier,
    :presence   => true,
    :uniqueness => { :scope => :page_id }
    
  # -- Instance Methods -----------------------------------------------------
  # Tag object that is using this block
  def tag
    @tag ||= page.tags(true).detect{|t| t.is_cms_block? && t.identifier == identifier}
  end

protected

  def prepare_files
    #on a create the page_id is set, but not the association for page
    if page.nil? && page_id
      @_page = Cms::Page.find(page_id)
    end
    puts "Block.prepare_files #{content.inspect} #{tag} #{page.tags(true)}"
    temp_files = [self.content].flatten.select do |f|
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
