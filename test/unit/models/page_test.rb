# encoding: utf-8
require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CmsPageTest < ActiveSupport::TestCase
  
  def test_fixtures_validity
    Cms::Page.all.each do |page|
      assert page.valid?, page.errors.full_messages.to_s
      assert_equal page.read_attribute(:content_cache), page.content(true), "page #{page.slug}"
    end
  end
  
  def test_validations
    page = Cms::Page.new
    page.save
    assert page.invalid?
    assert_has_errors_on page, :site_id, :layout, :slug, :label
  end
  
  def test_validation_of_parent_presence
    page = cms_sites(:default).pages.build(new_params)
    assert !page.parent
    assert page.valid?, page.errors.full_messages.to_s
    assert_equal cms_pages(:default), page.parent
  end
  
  def test_validation_of_parent_relationship
    page = cms_pages(:default)
    assert !page.parent
    page.parent = page
    assert page.invalid?
    assert_has_errors_on page, :parent_id
    page.parent = cms_pages(:child)
    assert page.invalid?
    assert_has_errors_on page, :parent_id
  end
  
  def test_validation_of_target_page
    page = cms_pages(:child)
    page.target_page = cms_pages(:default)
    page.save!
    assert_equal cms_pages(:default), page.target_page
    page.target_page = page
    assert page.invalid?
    assert_has_errors_on page, :target_page_id
  end
  
  def test_validation_of_slug
    page = cms_pages(:child)
    page.slug = 'slug.with.d0ts-and_things'
    assert page.valid?
    
    page.slug = 'inva lid'
    assert page.invalid?

    page.slug = 'acción'
    assert page.valid?
  end
  
  def test_label_assignment
    page = cms_sites(:default).pages.build(
      :slug   => 'test',
      :parent => cms_pages(:default),
      :layout => cms_layouts(:default)
    )
    assert page.valid?
    assert_equal 'Test', page.label
  end
  
  def test_creation
    assert_difference ['Cms::Page.count', 'Cms::Block.count'] do
      page = cms_sites(:default).pages.create!(
        :label  => 'test',
        :slug   => 'test',
        :parent => cms_pages(:default),
        :layout => cms_layouts(:default),
        :blocks_attributes => [
          { :identifier => 'default_page_text',
            :content    => 'test' }
        ]
      )
      assert page.is_published?, "page not published"
      assert_equal 1, page.position, "bad page position"
    end
  end
  
  def test_initialization_of_full_path
    page = Cms::Page.new
    assert_equal '/', page.full_path, "bad initial full path"
    
    page = Cms::Page.new(new_params)
    assert page.invalid?
    assert_has_errors_on page, :site_id
    
    page = cms_sites(:default).pages.build(new_params(:parent => cms_pages(:default)))
    assert page.valid?
    assert_equal '/test-page', page.full_path
    
    page = cms_sites(:default).pages.build(new_params(:parent => cms_pages(:child)))
    assert page.valid?
    assert_equal '/child-page/test-page', page.full_path
    
    Cms::Page.destroy_all
    page = cms_sites(:default).pages.build(new_params)
    assert page.valid?
    assert_equal '/', page.full_path
  end
  
  def test_sync_child_pages
    page = cms_pages(:child)
    page_1 = cms_sites(:default).pages.create!(new_params(:parent => page, :slug => 'test-page-1'))
    page_2 = cms_sites(:default).pages.create!(new_params(:parent => page, :slug => 'test-page-2'))
    page_3 = cms_sites(:default).pages.create!(new_params(:parent => page_2, :slug => 'test-page-3'))
    page_4 = cms_sites(:default).pages.create!(new_params(:parent => page_1, :slug => 'test-page-4'))
    assert_equal '/child-page/test-page-1', page_1.full_path, "bad fullpath on page 1"
    assert_equal '/child-page/test-page-2', page_2.full_path, "bad fullpath on page 2"
    assert_equal '/child-page/test-page-2/test-page-3', page_3.full_path, "bad fullpath on page 3"
    assert_equal '/child-page/test-page-1/test-page-4', page_4.full_path, "bad fullpath on page 4"
    
    page.update_attributes!(:slug => 'updated-page')
    assert_equal '/updated-page', page.full_path, "bad fullpath on page, after update"
    page_1.reload; page_2.reload; page_3.reload; page_4.reload
    assert_equal '/updated-page/test-page-1', page_1.full_path, "bad fullpath on page 1 after update"
    assert_equal '/updated-page/test-page-2', page_2.full_path, "bad fullpath on page 2 after update"
    assert_equal '/updated-page/test-page-2/test-page-3', page_3.full_path, "bad fullpath on page 3 after update"
    assert_equal '/updated-page/test-page-1/test-page-4', page_4.full_path, "bad fullpath on page 4 after update"
    
    page_2.update_attributes!(:parent => page_1)
    page_1.reload; page_2.reload; page_3.reload; page_4.reload
    assert_equal '/updated-page/test-page-1', page_1.full_path, "bad fullpath on page 1 after reorg"
    assert_equal '/updated-page/test-page-1/test-page-2', page_2.full_path, "bad fullpath on page 2 after reorg"
    assert_equal '/updated-page/test-page-1/test-page-2/test-page-3', page_3.full_path, "bad fullpath on page 3 after reorg"
    assert_equal '/updated-page/test-page-1/test-page-4', page_4.full_path, "bad fullpath on page 4 after reorg"
  end
  
  def test_children_count_updating
    page_1 = cms_pages(:default)
    page_2 = cms_pages(:child)
    assert_equal 1, page_1.children_count, "bad count page 1"
    assert_equal 0, page_2.children_count, "bad count page 2"
    
    page_3 = cms_sites(:default).pages.create!(new_params(:parent => page_2))
    page_1.reload; page_2.reload
    assert_equal 1, page_1.children_count, "bad count page 1 after create"
    assert_equal 1, page_2.children_count, "bad count page 2 after create"
    assert_equal 0, page_3.children_count, "bad count page 3 after create"
    
    page_3.update_attributes!(:parent => page_1)
    page_1.reload; page_2.reload
    assert_equal 2, page_1.children_count, "bad count page 1 after add"
    assert_equal 0, page_2.children_count, "bad count page 2 after add"
    
    page_3.destroy
    page_1.reload; page_2.reload
    assert_equal 1, page_1.children_count, "bad count page 1 after destroy"
    assert_equal 0, page_2.children_count, "bad count page 2 after destroy"
  end
  
  def test_cascading_destroy
    assert_difference 'Cms::Page.count', -2 do
      cms_pages(:default).destroy
    end
  end
  
  def test_options_for_select
    assert_equal ['Default Page', '. . Child Page'], 
      Cms::Page.options_for_select(cms_sites(:default)).collect{|t| t.first }
    assert_equal ['Default Page'], 
      Cms::Page.options_for_select(cms_sites(:default), cms_pages(:child)).collect{|t| t.first }
    assert_equal [], 
      Cms::Page.options_for_select(cms_sites(:default), cms_pages(:default))
    
    page = Cms::Page.new(new_params(:parent => cms_pages(:default)))
    assert_equal ['Default Page', '. . Child Page'],
      Cms::Page.options_for_select(cms_sites(:default), page).collect{|t| t.first }
  end
  
  def test_cms_blocks_attributes_accessor
    page = cms_pages(:default)
    assert_equal page.blocks.count, page.blocks_attributes.size
    # It should just matter that it is there not what position it shows up in..
    assert  page.blocks_attributes.detect { |a|
      a[:identifier] == "default_field_text" && a[:content] == "default_field_text_content"
    }
  end
  
  def test_content_caching
    page = cms_pages(:default)
    assert_equal page.read_attribute(:content_cache), page.content
    assert_equal page.read_attribute(:content_cache), page.content(true)
    
    page.update_attribute(:content_cache, 'changed')
    assert_equal page.read_attribute(:content_cache), page.content
    assert_equal page.read_attribute(:content_cache), page.content(true)
    assert_not_equal 'changed', page.read_attribute(:content_cache)
  end
  
  def test_scope_published
    assert_equal 2, Cms::Page.published.count
    cms_pages(:child).update_attribute(:is_published, false)
    assert_equal 1, Cms::Page.published.count
  end
  
  def test_root?
    assert cms_pages(:default).root?, "bad root"
    assert !cms_pages(:child).root?, "bad child"
  end
  
  def test_url
    assert_equal 'http://test.host/', cms_pages(:default).url
    assert_equal 'http://test.host/child-page', cms_pages(:child).url
  end

  def test_unicode_slug_escaping
    page = cms_pages(:child)
    page_1 = cms_sites(:default).pages.create!(new_params(:parent => page, :slug => 'tést-ünicode-slug'))
    assert_equal CGI::escape('tést-ünicode-slug'), page_1.escaped_slug
    assert_equal CGI::escape('/child-page/tést-ünicode-slug').gsub('%2F', '/'), page_1.escaped_full_path
  end

  def test_unicode_slug_unescaping
    page = cms_pages(:child)
    page_1 = cms_sites(:default).pages.create!(new_params(:parent => page, :slug => 'tést-ünicode-slug'))
    found_page = cms_sites(:default).pages.where(:escaped_slug => CGI::escape('tést-ünicode-slug')).first
    assert_equal 'tést-ünicode-slug', found_page.slug
    assert_equal '/child-page/tést-ünicode-slug', found_page.full_path
  end
  
protected
  
  def new_params(options = {})
    {
      :label  => 'Test Page',
      :slug   => 'test-page',
      :layout => cms_layouts(:default)
    }.merge(options)
  end
end
