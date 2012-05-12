class Cms::Orm::MongoMapper::Site
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  include ComfortableMexicanSofa::MongoMapper::HasRevisions
  include ComfortableMexicanSofa::MongoMapper::IsCategorized
  include ComfortableMexicanSofa::MongoMapper::IsMirrored


  #create_table "cms_sites", :force => true do |t|
  #  t.string  "label",                          :null => false
  #  t.string  "identifier",                     :null => false
  #  t.string  "hostname",                       :null => false
  #  t.string  "path"
  #  t.string  "locale",      :default => "en",  :null => false
  #  t.boolean "is_mirrored", :default => false, :null => false
  #end

  #key :type, String, :null => false
  key :label, String, :null => false
  key :identifier, String, :null => false
  key :hostname, String, :null => false
  key :path, String, :default => nil
  key :locale, String, :default => "en", :null => false
  key :is_mirrored, Boolean, :default => false, :null => false

  attr_accessible :label, :identifier, :hostname, :path, :locale, :is_mirrored

  # -- Relationships --------------------------------------------------------
  many :layouts,    :class_name => "Cms::Layout", :autosave => true, :dependent => :delete_all do
    def roots
      where(:parent_id => nil)
    end
  end
  many :pages,      :class_name => "Cms::Page", :autosave => true, :dependent => :delete_all do
    def roots
      where(:parent_id => nil)
    end
  end
  many :snippets,   :class_name => "Cms::Snippet", :autosave => true, :dependent => :delete_all do
    def by_position
      order(:position)
    end
  end
  many :files,      :class_name => "Cms::File", :autosave => true, :dependent => :destroy   do
    def images
      where(:file_content_type => Cms::File::IMAGE_MIMETYPES)
    end
    def not_images
      where(:file_content_type.nin() =>  Cms::File::IMAGE_MIMETYPES)
    end

  end
  many :categories, :class_name => "Cms::Category", :autosave => true, :dependent => :delete_all do
    def by_type(type)
      where(:categorized_type => type)
    end
  end


  # -- Scopes ---------------------------------------------------------------
  scope :mirrored, where(:is_mirrored => true)

  # When site is marked as a mirror we need to sync its structure
  # with other mirrors.
  def sync_mirrors
    return unless is_mirrored_changed? && is_mirrored?

    [self, Cms::Site.mirrored.where(:id.ne => id).first].compact.each do |site|
      # The MongoMapper scope "roots" doesn't work here
      (site.layouts.where(:parent_id => nil).all + site.layouts.where(:parent_id => nil).all.map(&:descendants)).flatten.map(&:sync_mirror)
      (site.pages.where(:parent_id => nil).all + site.pages.where(:parent_id => nil).all.map(&:descendants)).flatten.map(&:sync_mirror)
      site.snippets.map(&:sync_mirror)
    end
  end
end