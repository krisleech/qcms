class Admin::DocumentsController < Admin::AdminController
  unloadable
  before_filter :find_document, :except => [:index]
  before_filter :catch_sti_problem, :only => [:update]

  cache_sweeper :document_sweeper, :only => [:create, :update, :destroy]

  def index    
    @documents = Document.roots.sort_by(&:position)
  end

  def show    
    render :text => "Document Not Found [#{params[:id]}]" and return unless @document
    render :template => admin_view_for('show')
  end

  def new    
    @document.type = params[:type] || 'Document'
    if params[:parent]
      @document.parent = Document.find(params[:parent])
      @document.meta_definition = @document.parent.meta_definition.children.by_label(params[:label]).first
    else
      @document.meta_definition = MetaDefinition.find_by_label_path(params[:label_path])
    end    
    @document.label = params[:label] || @document.meta_definition.label
    render :template => admin_view_for('new')
  end

  def create    
    @document = Document.create(params[:document])
    @document.type = params[:document][:type] || 'Document'
    @document.author = current_user
    if @document.save
      flash[:notice] = "Succesfully Saved"
      redirect_to parent_path
    else           
      render :template => admin_view_for('new')
    end    
  end

  def edit    
    render :template => admin_view_for('edit')
  end

  def update
    if @document.update_attributes(params[:document])
      flash[:notice] = "Succesfully Saved"
      redirect_to parent_path
    else
      render :template => admin_view_for('edit')
    end
  end

  def destroy    
    @document.destroy
    redirect_to parent_path
  end

  def up    
    @document.move_higher
    redirect_to parent_path
  end

  def down    
    @document.move_lower
    redirect_to parent_path
  end

  # Generate a view from template.erb
  def generate_template
    if request.post?
      template = File.new("#{RAILS_ROOT}/app/views/pages/#{@document.meta_definition.label_path.gsub('/', '.')}.html.erb", 'w')
      template.write(ERB.new(IO.read("#{RAILS_ROOT}/app/views/pages/template.erb")).result(binding))
      template.close
    end
    @document.touch # delete cache (FIXME: Not ideal)
    redirect_to document_path(@document)
  end

  private
  
  def find_document
    if params[:id]
      @document = Document.find(params[:id])
    else
      @document = Document.new
    end
  end

  def parent_path
    if @document.parent
      admin_document_path(@document.parent.id)
    else
      admin_dashboard_path
    end
  end


  # eg. my_first_post.html.erb, blog.post.comment.html.erb, default.html.erb
  def admin_view_for(action, options = {})
    options[:extension] = '.html.erb'

    filenames = [@document.permalink, @document.meta_definition.label_path.gsub('/', '.'), 'default']
    
    view_paths.each do | view_path |
      filenames.each do | filename |
        next if filename.nil?
        target = File.join('admin', 'documents', filename + '.' + action) + options[:extension]
        target_with_view_path = File.join(view_path, target)
        if File.exists? target_with_view_path
          headers['content-type'] = 'text/html' # Otherwise wrong content-type is set due to multiple file extensions
          logger.debug 'TEMPLATE FOUND: ' + target_with_view_path
          return target
        else
          logger.debug 'TEMPLATE NOT FOR: ' + target_with_view_path
        end
      end
    end
    raise 'No Template found'
  end


  # No idea why this happens but if the inputs are (incorrectly) named page[field] instead of document[field] you get
  # params[:document] from now where. This would be okay but sometimes fields appear to be missing when using fckeditor(!?!)
  # For the new form @document is_a? Document (not yet 'typed' via STI), but when editing it is_a? Page or Folder...
  # To get the correct input names @document needs to be type cast to Document class
  # Example: form_for @document.becomes(Document)
  def catch_sti_problem
    return unless RAILS_ENV == 'development'
    if params[:document] && params[:page]
      raise 'Both params[:document] and params[:page] found, you might need to add @document.becomes(Document) to get the correct input names'
    end
  end
end