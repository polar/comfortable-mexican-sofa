class CmsAdmin::RevisionsController < CmsAdmin::BaseController
  helper_method :revision_path_to, :revert_revision_path

  before_filter :load_record
  before_filter :load_revision, :except => :index
  
  def index
    @revision_id = @record.revisions.first.try(:id) || 0
    redirect_to_show_record_revision
  end
  
  def show
    case @record
    when Cms::Page
      @current_content    = @record.blocks.inject({}){|c, b| c[b.identifier] = b.content; c }
      @versioned_content  = @record.blocks.inject({}){|c, b| c[b.identifier] = @revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
    else
      @current_content    = @record.revision_fields.inject({}){|c, f| c[f] = @record.send(f); c }
      @versioned_content  = @record.revision_fields.inject({}){|c, f| c[f] = @revision.data[f]; c }
    end
  end
  
  def revert
    @record.restore_from_revision(@revision)
    flash[:notice] = I18n.t('cms.revisions.reverted')
    redirect_to_edit_record
  end
  
protected

  def revision_path_to(id)
    case @record
      when Cms::Layout then
        cms_admin_site_layout_revision_path(@site, @record, id)
      when Cms::Page then
        cms_admin_site_page_revision_path(@site, @record, id)
      when Cms::Snippet then
        cms_admin_site_snippet_revision_path(@site, @record, id)
    end

  end

  def revert_revision_path
    case @record
      when Cms::Layout then
        revert_cms_admin_site_layout_revision_path(@site, @record, @revision)
      when Cms::Page then
        revert_cms_admin_site_page_revision_path(@site, @record, @revision)
      when Cms::Snippet then
        revert_cms_admin_site_snippet_revision_path(@site, @record, @revision)
    end
  end

  def load_record
    @record = if params[:layout_id]
      Cms::Layout.find(params[:layout_id])
    elsif params[:page_id]
      Cms::Page.find(params[:page_id])
    elsif params[:snippet_id]
      Cms::Snippet.find(params[:snippet_id])
    end
    raise  ComfortableMexicanSofa.ModelNotFound if @record.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    flash[:error] = I18n.t('cms.revisions.record_not_found')
    redirect_to cms_admin_path
  end
  
  def load_revision
    @revision = @record.revisions.find(params[:id])
    raise  ComfortableMexicanSofa.ModelNotFound if @revision.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    flash[:error] = I18n.t('cms.revisions.not_found')
    redirect_to_edit_record
  end

  def redirect_to_edit_record
    redirect_to case @record
                  when Cms::Layout  then edit_cms_admin_site_layout_path(@site, @record)
                  when Cms::Page    then edit_cms_admin_site_page_path(@site, @record)
                  when Cms::Snippet then edit_cms_admin_site_snippet_path(@site, @record)
                end
  end

  def redirect_to_show_record_revision
    redirect_to case @record
                  when Cms::Layout  then cms_admin_site_layout_revision_path(@site, @record, @revision_id)
                  when Cms::Page    then cms_admin_site_page_revision_path(@site, @record, @revision_id)
                  when Cms::Snippet then cms_admin_site_snippet_revision_path(@site, @record, @revision_id)
                end
  end
  
end