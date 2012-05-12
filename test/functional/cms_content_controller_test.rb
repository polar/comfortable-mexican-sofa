require File.expand_path('../test_helper', File.dirname(__FILE__))

class CmsContentControllerTest < ActionController::TestCase

  def test_render_page
    get :render_html, :cms_path => ''
    assert_equal Cms::Site.make!, assigns(:cms_site)
    assert_equal Cms::Layout.make!, assigns(:cms_layout)
    assert_equal Cms::Page.make!, assigns(:cms_page)
    
    assert_response :success
    assert_equal rendered_content_formatter(
      '
      layout_content_a
      default_page_text_content_a
      default_snippet_content
      default_page_text_content_b
      layout_content_b
      default_snippet_content
      layout_content_c'
    ), response.body
    assert_equal 'text/html', response.content_type
  end
  
  def test_render_page_with_app_layout
    Cms::Layout.make!.update_attribute(:app_layout, 'cms_admin')
    get :render_html, :cms_path => ''
    assert_response :success
    assert assigns(:cms_page)
    assert_select "body[class='c_cms_content a_render_html']"
  end
  
  def test_render_page_with_xhr
    Cms::Layout.make!.update_attribute(:app_layout, 'cms_admin')
    xhr :get, :render_html, :cms_path => ''
    assert_response :success
    assert assigns(:cms_page)
    assert_no_select "body[class='c_cms_content a_render_html']"
  end
  
  def test_render_page_not_found
    assert_exception_raised ActionController::RoutingError, 'Page Not Found' do
      get :render_html, :cms_path => 'doesnotexist'
    end
  end
  
  def test_render_page_not_found_with_custom_404
    page = Cms::Site.make!.pages.create!(
      :label          => '404',
      :slug           => '404',
      :parent_id      => Cms::Page.make!.id,
      :layout_id      => Cms::Layout.make!.id,
      :is_published   => '1',
      :blocks_attributes => [
        { :identifier => 'default_page_text',
          :content    => 'custom 404 page content' }
      ]
    )
    assert_equal '/404', page.full_path
    assert page.is_published?
    get :render_html, :cms_path => 'doesnotexist'
    assert_response 404
    assert assigns(:cms_page)
    assert_match /custom 404 page content/, response.body
  end
  
  def test_render_page_with_no_site
    Cms::Site.destroy_all
    
    assert_exception_raised ActionController::RoutingError, 'Site Not Found' do
      get :render_html, :cms_path => ''
    end
  end
  
  def test_render_page_with_no_layout
    Cms::Layout.destroy_all
    
    get :render_html, :cms_path => ''
    assert_response 404
    assert_equal 'Layout Not Found', response.body
  end
  
  def test_render_page_with_redirect
    site = Cms::Site.make!
    parent = Cms::Page.make!(:site => site)
    child = Cms::Page.make!(:site => site, :parent => parent, :slug => "child-page")
    child.update_attribute(:target_page, parent)
    assert_equal page, child.target_page
    get :render_html, :cms_path => 'child-page'
    assert_response :redirect
    assert_redirected_to '/'
  end
  
  def test_render_page_unpublished
    page = Cms::Page.make!
    page.update_attribute(:is_published, false)
    
    assert_exception_raised ActionController::RoutingError, 'Page Not Found' do
      get :render_html, :cms_path => ''
    end
  end
  
  def test_render_page_with_irb_disabled
    assert_equal false, ComfortableMexicanSofa.config.allow_irb
    
    irb_page = Cms::Site.make!.pages.create!(
      :label          => 'irb',
      :slug           => 'irb',
      :parent_id      => Cms::Page.make!.id,
      :layout_id      => Cms::Layout.make!.id,
      :is_published   => '1',
      :blocks_attributes => [
        { :identifier => 'default_page_text',
          :content    => 'text <%= 2 + 2 %> text' }
      ]
    )
    get :render_html, :cms_path => 'irb'
    assert_response :success
    assert_match "text &lt;%= 2 + 2 %&gt; text", response.body
  end
  
  def test_render_page_with_irb_enabled
    ComfortableMexicanSofa.config.allow_irb = true
    
    irb_page = Cms::Site.make!.pages.create!(
      :label          => 'irb',
      :slug           => 'irb',
      :parent_id      => Cms::Page.make!.id,
      :layout_id  => Cms::Layout.make!.id,
      :is_published   => '1',
      :blocks_attributes => [
        { :identifier => 'default_page_text',
          :content    => 'text <%= 2 + 2 %> text' }
      ]
    )
    get :render_html, :cms_path => 'irb'
    assert_response :success
    assert_match "text 4 text", response.body
  end
  
  def test_render_css
    get :render_css, :site_id => Cms::Site.make!.id, :identifier => Cms::Layout.make!.identifier
    assert_response :success
    assert_match 'text/css', response.content_type
    assert_equal Cms::Layout.make!.css, response.body
  end
  
  def test_render_css_not_found
    get :render_css, :site_id => Cms::Site.make!.id, :identifier => 'bogus'
    assert_response 404
  end
  
  def test_render_js
    get :render_js, :site_id => Cms::Site.make!.id, :identifier => Cms::Layout.make!.identifier
    assert_response :success
    assert_equal 'text/javascript', response.content_type
    assert_equal Cms::Layout.make!.js, response.body
  end
  
  def test_render_js_not_found
    get :render_js, :site_id => Cms::Site.make!.id, :identifier => 'bogus'
    assert_response 404
  end

  def test_render_sitemap
    get :render_sitemap, :format => :xml
    assert_response :success
    assert_match '<loc>http://test.host/child-page</loc>', response.body
  end

  def test_render_sitemap_with_path
    site = Cms::Site.make!
    site.update_attribute(:path, 'en')
    
    get :render_sitemap, :cms_path => site.path, :format => :xml
    assert_response :success
    assert_equal Cms::Site.make!, assigns(:cms_site)
    assert_match '<loc>http://test.host/en/child-page</loc>', response.body
  end
  
  def test_render_sitemap_with_path_invalid_with_single_site
    site = Cms::Site.make!
    site.update_attribute(:path, 'en')
    
    get :render_sitemap, :cms_path => 'fr', :format => :xml
    assert_response :success
    assert_equal Cms::Site.make!, assigns(:cms_site)
    assert_match '<loc>http://test.host/en/child-page</loc>', response.body
  end

  class TestRenderException
    def self.callback(cms_site, view, xml)
      xml.url do
        # make sure we have the view
        xml.loc view.url_for("http://test.host/test_render")
        xml.lastmod 2.days.ago.strftime('%Y-%m-%d')
      end
    end
  end

  def test_rendering_sitemap_with_extensions
    ComfortableMexicanSofa::Sitemap.register_extension(TestRenderException.method(:callback))
    get :render_sitemap, :format => :xml
    assert_response :success
    assert_match '<loc>http://test.host/test_render</loc>', response.body
  end

end
