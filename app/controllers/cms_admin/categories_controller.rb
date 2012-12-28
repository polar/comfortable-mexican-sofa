class CmsAdmin::CategoriesController < CmsAdmin::BaseController
  
  before_filter :load_category,  :only => [:edit, :update, :destroy]

  def index
    @categories = @site.categories.all
    render :nothing => true
  end

  def edit
    render
  end
  
  def create
    @category = @site.categories.create!(params[:category])
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    render :nothing => true
  end
  
  def update
    @category.update_attributes!(params[:category])
  rescue ComfortableMexicanSofa.ModelInvalid
    logger.detailed_error($!)
    render :nothing => true
  end
  
  def destroy
    @category.destroy
  end
  
protected
  
  def load_category
    @category = @site.categories.find(params[:id])
    raise ComfortableMexicanSofa.ModelNotFound if @category.nil?
  rescue ComfortableMexicanSofa.ModelNotFound
    render :nothing => true
  end
  
end