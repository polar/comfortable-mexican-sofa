class CmsAdmin::PreviewController < CmsAdmin::BaseController

  clear_helpers
  helper ComfortableMexicanSofa.config.preview_helpers

  def preview
    @page = load_cms_page

    layout = @page.layout.app_layout.blank?? false : @page.layout.app_layout
    @cms_site   = @page.site
    @cms_layout = @page.layout
    @cms_page   = @page
    render :inline => @page.content(true), :layout => layout
  end

  protected

  def load_cms_page
    page = @site.pages.find(params[:id])
    raise ComfortableMexicanSofa.ModelNotFound if page.nil?
    page.attributes = params[:page]
    page.layout ||= (page.parent && page.parent.layout || @site.layouts.roots.first)
    return page
  rescue ComfortableMexicanSofa.ModelNotFound
    page = @site.pages.build(params[:page])
    page.parent ||= (@site.pages.find_by_id(params[:parent_id]) || @site.pages.roots.first)
    page.layout ||= (page.parent && page.parent.layout || @site.layouts.roots.first)
    return page
  end

end