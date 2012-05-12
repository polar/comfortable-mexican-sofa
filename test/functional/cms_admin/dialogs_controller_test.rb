require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CmsAdmin::DialogsControllerTest < ActionController::TestCase

  def test_get_image_dialog
    get :show, :site_id => Cms::Site.make!, :type => 'image'
    assert_response :success
    assert_template 'image'
    assert_select "input[name=image_url]"
  end
  
  def test_get_link_dialog
    get :show, :site_id => Cms::Site.make!, :type => 'link'
    assert_response :success
    assert_template 'link'
  end
  
  def test_get_invalid
    get :show, :site_id => Cms::Site.make!, :type => 'invalid'
    assert_response :success
    assert_blank response.body
  end

end