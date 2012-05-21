class Upgrade < ActiveRecord::Migration
  def self.up
    add_column :cms_blocks, :type, :string
    add_column :cms_categorizations, :type, :string
    add_column :cms_categories, :type, :string
    add_column :cms_files, :type, :string
    change_column_default :cms_files, :position, -1

    add_column :cms_layouts, :type, :string
    change_column_default :cms_layouts, :position, -1

    change_table :cms_pages do  |t|
      t.string :type
      t.boolean :content_dirty
    end
    rename_column :cms_pages, :content, :content_cache
    change_column_default :cms_pages, :position, -1

    add_column :cms_revisions, :type, :string
    add_column :cms_sites, :type, :string
    add_column :cms_sites, :created_at, :datetime
    add_column :cms_snippets, :type, :string
    change_column_default :cms_snippets, :position, -1
  end

  def self.down
    remove_column :cms_blocks, :type
    remove_column :cms_categorizations, :type
    remove_column :cms_categories, :type
    remove_column :cms_files, :type
    remove_column :cms_layouts, :type

    change_table :cms_pages do  |t|
      t.remove :type
      t.remove :content_dirty
    end
    rename_column :cms_pages, :content_cache, :content

    remove_column :cms_revisions, :type
    remove_column :cms_sites, :type
    remove_column :cms_sites, :created_at
    remove_column :cms_snippets, :type
  end
end
