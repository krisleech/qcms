class Admin::MetaDefinitionsController < Admin::AdminController
  unloadable
  def index
    @meta_definition = MetaDefinition.roots
  end

  def show
  end

  def new    
  end

  def create
  end

  def edit    
  end

  def update
    @meta_definition = MetaDefinition.find(params[:id])
    if @meta_definition.update_attributes(params[:meta_definition])
      flash[:notice] = "Succesfully Saved"      
    else
      flash[:notice] = 'Not saved'            
    end
    redirect_to admin_document_path(params[:document_id])
  end

 


  

  private
  
  
end
