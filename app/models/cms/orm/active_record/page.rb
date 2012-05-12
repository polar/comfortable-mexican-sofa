# encoding: utf-8
class Cms::Orm::ActiveRecord::Page < ActiveRecord::Base

  include ComfortableMexicanSofa::ActiveRecord::ActsAsTree
  include ComfortableMexicanSofa::ActiveRecord::HasRevisions
  include ComfortableMexicanSofa::ActiveRecord::IsCategorized
  include ComfortableMexicanSofa::ActiveRecord::IsMirrored

  ComfortableMexicanSofa.establish_connection(self)

  attr_accessor :tags,
                :blocks_attributes_changed

  self.table_name = 'cms_pages'
  
  # -- Relationships --------------------------------------------------------
  belongs_to :site, :class_name => "Cms::Site"
  belongs_to :layout, :class_name => "Cms::Layout"
  belongs_to :target_page, :class_name => 'Cms::Page'
  has_many :blocks, :class_name => "Cms::Block",
    :autosave   => true,
    :dependent  => :destroy


  # -- Scopes ---------------------------------------------------------------
  default_scope order('cms_pages.position')
  scope :published, where(:is_published => true)


  # Transforms existing cms_block information into a hash that can be used
  # during form processing. That's the only way to modify cms_blocks.
  def blocks_attributes(was = false)
    self.blocks.collect do |block|
      # Processing Content will build new blocks without content (perhaps to be picked up later?)
      # In any case, we really don't want to be counting new blocks that
      # don't have any content.'
      if !block.new? || block.content
        block_attr = {}
        block_attr[:identifier] = block.identifier
        block_attr[:content]    = was ? block.content_was : block.content
        block_attr
      end

    end
  end

  # Array of block hashes in the following format:
  #   [
  #     { :identifier => 'block_1', :content => 'block content' },
  #     { :identifier => 'block_2', :content => 'block content' }
  #   ]
  def blocks_attributes=(block_hashes = [])
    block_hashes = block_hashes.values if block_hashes.is_a?(Hash)
    block_hashes.each do |block_hash|
      block_hash.symbolize_keys! unless block_hash.is_a?(HashWithIndifferentAccess)
      block =
          self.blocks.detect{|b| b.identifier == block_hash[:identifier]} ||
              self.blocks.build(:identifier => block_hash[:identifier])
      block.content = block_hash[:content]
      self.blocks_attributes_changed = self.blocks_attributes_changed || block.content_changed?
    end
  end

end
