require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CreateTest < ActiveSupport::TestCase

  # This method istesting the new and saves for AR and MongoMapper
  def test_create_and_new
    site = Cms::Site.new(:label => "my site", :hostname => "localhost", :identifier => "site1")
    site.save!
    layout = Cms::Layout.new(:site => site, :label => "my layout", :identifier => "layout1")
    layout.save!
    page = Cms::Page.new(:site => site, :layout => layout, :label => "page1", :slug => "page1")
    page.save!

    assert_equal site, layout.site, "bad site"
    assert_equal site, page.site, "bad site"
    assert_equal layout, page.layout, "bad layout"

    puts "===================LAYOUT RELOAD=========================="
    layout.reload
    assert_equal site, layout.site, "bad site after layout reload"

    puts "===================PAGE RELOAD=========================="
    page.save!
    page.reload
    assert_equal site, page.site, "bad site after page reload"
    assert_equal layout, page.layout, "bad layout after page reload"
  end

end
