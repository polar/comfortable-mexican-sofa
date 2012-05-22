
require 'blueprints/block'
require 'blueprints/categorization'
require "blueprints/category"
require "blueprints/file"
require "blueprints/layout"
require "blueprints/page"
require "blueprints/revision"
require "blueprints/site"
require "blueprints/snippet"

if ComfortableMexicanSofa.config.backend.to_s == "mongo_mapper"
  DatabaseCleaner[:mongo_mapper].strategy = :truncation
end

if ComfortableMexicanSofa.config.backend.to_s == "active_record"
  DatabaseCleaner[:active_record].strategy = :truncation
end


module BlueprintFixtureMap

  def cms_blocks(key)
    return @cms_blocks[key]
  end

  def cms_categorizations(key)
    return @cms_categorizations[key]
  end

  def cms_categories(key)
    return @cms_categories[key]
  end

  def cms_files(key)
    return @cms_files[key]
  end

  def cms_pages(key)
    return @cms_pages[key]
  end

  def cms_snippets(key)
    return @cms_snippets[key]
  end

  def cms_layouts(key)
    return @cms_layouts[key]
  end

  def cms_revisions(key)
    return @cms_revisions[key]
  end

  def cms_sites(key)
    return @cms_sites[key]
  end

  def setup_blueprints
    site = Cms::Site.make!(:default)

    layout = Cms::Layout.make(:default)
    site.layouts << layout
    snippet = Cms::Snippet.make(:default)
    site.snippets << snippet
    category = Cms::Category.make(:default)
    site.categories << category
    file = Cms::File.make(:default)
    site.files << file
    site.save!

    page = Cms::Page.make(:default, :layout => layout)
    site.pages << page

    assert page.persisted?, "page was not saved."

    block1 = page.blocks.first
    block1.content = "default_page_text_content_a\n{{cms:snippet:default}}\ndefault_page_text_content_b"
    block1.save!
    block2 = Cms::Block.make(:default_field_text)
    page.blocks << block2

    assert_equal 2, page.blocks.count

    categorization = Cms::Categorization.make!(:default, :category => category, :categorized => file)
    file.reload

    # Need to update page.  This would happen automatically if we used sites.snippets.create!
    page.save!
    assert_equal 2, page.blocks.count
    assert_equal "default_page_text_content_a\n{{cms:snippet:default}}\ndefault_page_text_content_b", block1.content
    assert_equal "default_field_text_content", block2.content
    assert_equal "\nlayout_content_a\ndefault_page_text_content_a\ndefault_snippet_content\ndefault_page_text_content_b\nlayout_content_b\ndefault_snippet_content\nlayout_content_c", page.content_cache

    @cms_blocks = { :default_field_text => block1, :default_page_text => block2 }
    @cms_pages = {:default => page }
    @cms_sites = {:default => site }
    @cms_categories = { :default => category }
    @cms_files = { :default => file }
    @cms_categorizations = { :default => categorization }
    @cms_snippets = { :default => snippet }
    @cms_layouts = { :default => layout }
    @cms_revisions = {}

    @cms_blocks[:default_field_text] = block2

    # I don't know how the page generates this.
    @cms_blocks[:default_page_text] = block1


    @cms_layouts[:nested] =
        Cms::Layout.make(:nested)
    site.layouts <<  @cms_layouts[:nested]

    @cms_layouts[:child] =
        Cms::Layout.make(:child, :parent => @cms_layouts[:nested])
    site.layouts << @cms_layouts[:child]

    @cms_pages[:child] =
        Cms::Page.make(:child, :layout => layout)
    site.pages << @cms_pages[:child]  # automatically makes @cms_pages[:default] its parent
    page.reload
    assert_equal page.children_count, page.children.count

    @cms_revisions[:layout] =
        Cms::Revision.make!(:layout, :record => layout)
    @cms_revisions[:page] =
        Cms::Revision.make!(:page, :record => page)
    @cms_revisions[:snippet] =
        Cms::Revision.make!(:snippet, :record => snippet)

    @cms_sites[:with_path] = Cms::Site.make!(:with_path)

    page.reload
    layout.reload
    @cms_layouts[:child].reload
    @cms_layouts[:nested].reload
    snippet.reload
    site.reload
    @cms_pages[:child].reload
  end
end

