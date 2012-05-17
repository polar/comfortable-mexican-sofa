class Upgrade < ActiveRecord::Migration
  def self.up
    add_column :cms_blocks, :type, :string
    add_column :cms_categorizations, :type, :string
    add_column :cms_categories, :type, :string
    add_column :cms_files, :type, :string
    add_column :cms_layouts, :type, :string

    change_table :cms_pages do  |t|
      t.string :type
      t.remove :slug
      t.string :escaped_slug

      t.remove :full_path
      t.string :escaped_full_path

      t.remove :content
      t.boolean :content_dirty
      t.string :content_cache
    end

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

    change_table :cms_pages do  |t|
      t.remove :type
      t.string :slug
      t.remove :escaped_slug

      t.string :full_path
      t.remove :escaped_full_path

      t.string :content
      t.remove :content_dirty
      t.remove :content_cache
    end

    remove_column :cms_revisions, :type
    remove_column :cms_sites, :type
    remove_column :cms_snippets, :type
  end
end