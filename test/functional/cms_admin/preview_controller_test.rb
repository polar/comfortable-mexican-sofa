require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CmsAdmin::PreviewControllerTest < ActionController::TestCase

  def test_creation_preview
    site    = cms_sites(:default)
    layout  = cms_layouts(:default)
    
    assert_no_difference 'Cms::Page.count' do
      get :preview, :site_id => site, :page => {
        :label      => 'Test Page',
        :slug       => 'test-page',
        :parent_id  => cms_pages(:default).id,
        :layout_id  => layout.id,
        :blocks_attributes => [
          { :identifier => 'default_page_text',
            :content    => 'preview content' }
        ]
      }
      assert_response :success
      assert_match /preview content/, response.body
      
      assert_equal site, assigns(:cms_site)
      assert_equal layout, assigns(:cms_layout)
      assert assigns(:cms_page)
      assert assigns(:cms_page).new_record?
    end
  end

  def test_update_preview
    page = cms_pages(:default)
    assert_no_difference 'Cms::Page.count' do
      get :preview, :site_id => page.site, :id => page, :page => {
        :label => 'Updated Label',
        :blocks_attributes => [
          { :identifier => 'default_page_text',
            :content    => 'preview content' }
        ]
      }
      assert_response :success
      assert_match /preview content/, response.body
      page.reload
      assert_not_equal 'Updated Label', page.label
      
      assert_equal page.site,   assigns(:cms_site)
      assert_equal page.layout, assigns(:cms_layout)
      assert_equal page,        assigns(:cms_page)
    end
  end

end