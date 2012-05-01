class UpgradeTo160 < ActiveRecord::Migration
  def self.up
    add_column :cms_blocks, :type, :string
    add_column :cms_categorizations, :type, :string
    add_column :cms_categories, :type, :string
    add_column :cms_files, :type, :string
    add_column :cms_layouts, :type, :string
    add_column :cms_pages, :type, :string
    add_column :cms_revisions, :type, :string
    add_column :cms_sites, :type, :string
    add_column :cms_snippets, :type, :string
  end

  def self.down
    remove_column :cms_blocks, :type
    remove_column :cms_categorizations, :type
    remove_column :cms_categories, :type
    remove_column :cms_files, :type
    remove_column :cms_layouts, :type
    remove_column :cms_pages, :type
    remove_column :cms_revisions, :type
    remove_column :cms_sites, :type
    remove_column :cms_snippets, :type
  end
end