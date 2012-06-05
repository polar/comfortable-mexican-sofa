class TrialsController < ActionController::Base

  def index
    @site = Cms::Site.find_by_identifier("default-site")
    @trials = []
    @trials << Trial.new(:hello => "Hello ")
    @trials << Trial.new(:hello => "World!")
  end

  def show
    @trial = Trial.new(:hello => "world!")
  end
end
