require File.expand_path('../test_helper', File.dirname(__FILE__))
require File.expand_path("../test_app/config/application", File.dirname(__FILE__))

class TrialsControllerTest < ActionController::TestCase

  # Tests the basic functionality of the application
  def test_basic_functionality
    @routes = Rails.application.routes
    get :show
    assert assigns(:trial)
    assert_equal "world!", assigns(:trial).hello
    assert_response 200
    assert_equal assigns(:trial).hello, response.body
  end

  # Tests the rendering of the controller view context through the page pointed to by the index template
  def test_index_renders_partial_index_via_cms_page
    @routes = Rails.application.routes

    site = cms_sites(:default)

    # This layout renders the "content" block of a page as is.
    layout = site.layouts.create!(
        :identifier => "test",
        :label => "Test Layout",
        :app_layout => "application",
        :content => "{{ cms:page:content }}"
    )

    # This page renders the TrailTag.
    # The content block renders partial "trails/_index" through the TrialTag
    site.pages.create!(
      :slug => "trials",
      :layout => layout,
      :blocks_attributes => [
          { :identifier => 'content',
            :content    => '{{ cms:trial }}' }
      ])

    get :index
    assert assigns(:site)
    assert_equal site, assigns(:site)
    assert assigns(:trials)
    assert_response 200
    response_string = assigns(:trials).collect {|t| t.hello}.join("")
    assert_equal response_string, response.body
  end
end
