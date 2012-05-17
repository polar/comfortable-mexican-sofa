class CmsAdmin::SnippetsController < CmsAdmin::BaseController

  before_filter :build_snippet, :only => [:new, :create]
  before_filter :load_snippet,  :only => [:edit, :update, :destroy]

  def index
    return redirect_to :action => :new if @site.snippets.count == 0
    # TODO: Fix for ActiveRecord
    #@snippets = @site.snippets.includes(:categories).for_category(params[:category])
    @snippets = @site.snippets.categorized(params[:category]).all
  end

  def new
    render
  end

  def edit
    render
  end

  def create
    @snippet.save!
    flash[:notice] = I18n.t('cms.snippets.created')
    redirect_to :action => :edit, :id => @snippet
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.snippets.creation_failure')
    render :action => :new
  end

  def update
    @snippet.update_attributes!(params[:snippet])
    flash[:notice] = I18n.t('cms.snippets.updated')
    redirect_to :action => :edit, :id => @snippet
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.snippets.update_failure')
    render :action => :edit
  end

  def destroy
    @snippet.destroy
    flash[:notice] = I18n.t('cms.snippets.deleted')
    redirect_to :action => :index
  end
  
  def reorder
    (params[:cms_snippet] || []).each_with_index do |id, index|
      Cms::Snippet.where(:id => id).all.each do |s|
        s.update_attributes(:position => index)
      end
    end
    render :nothing => true
  end

protected

  def build_snippet
    @snippet = @site.snippets.build(params[:snippet])
  end

  def load_snippet
    @snippet = @site.snippets.find(params[:id])
    raise ComfortableMexicanSofa.ModelNotFound if @snippet.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    flash[:error] = I18n.t('cms.snippets.not_found')
    redirect_to :action => :index
  end
end
