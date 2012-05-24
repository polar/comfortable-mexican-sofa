class CmsAdmin::LayoutsController < CmsAdmin::BaseController

  before_filter :build_layout,  :only => [:new, :create]
  before_filter :load_layout,   :only => [:edit, :update, :destroy]

  def index
    return redirect_to :action => :new if @site.layouts.count == 0
    @layouts = @site.layouts.roots.all
  end

  def new
    render
  end

  def edit
    render
  end

  def create
    @layout.save!
    flash[:notice] = I18n.t('cms.layouts.created')
    redirect_to :action => :edit, :id => @layout
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.layouts.creation_failure')
    render :action => :new
  end

  def update
    @layout.update_attributes!(params[:layout])
    flash[:notice] = I18n.t('cms.layouts.updated')
    redirect_to :action => :edit, :id => @layout
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    flash.now[:error] = I18n.t('cms.layouts.update_failure')
    render :action => :edit
  end

  def destroy
    @layout.destroy
    flash[:notice] = I18n.t('cms.layouts.deleted')
    redirect_to :action => :index
  end
  
  def reorder
    (params[:cms_layout] || []).each_with_index do |id, index|
      Cms::Layout.where(:id => id).all.each do |layout|
        layout.update_attributes!(:position => index)
      end
    end
    render :nothing => true
  end

protected

  def build_layout
    @layout = @site.layouts.build(params[:layout])
    @layout.parent  ||= Cms::Layout.find_by_id(params[:parent_id])
    @layout.content ||= '{{ cms:page:content:text }}'
  end

  def load_layout
    @layout = @site.layouts.find(params[:id])
    raise ComfortableMexicanSofa.ModelNotFound if @layout.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    flash[:error] = I18n.t('cms.layouts.not_found')
    redirect_to :action => :index
  end

end
