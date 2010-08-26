class DocumentsController < ApplicationController
  unloadable
  skip_before_filter  :require_user

  # Show a document:
  # Route using catch-all, /*path, or, pass specific 'id', :path => 'gallery'
  def show    
    render :file => cache_file and return if cached_file?
    
    @document = Document.find_by_path(request_path)
  
    raise ActiveRecord::RecordNotFound unless @document and (@document.published? or @document.allowed? current_user, 'read')

    respond_to do |format|
      format.html do
        setup_view_environment
        render :template => view_for
      end
      format.xml { render :xml => @document.to_xml(:only => [:title, :summary, :body, :published_at, :permalink]) }
      format.rss { render :template => 'pages/feed.rss.builder' }
    end

    cache_this_page!
  end
  
  # Show all pages in any Document for a particular month/year
  # /*path/archive/:month/:year
  def archive
    render :file => cache_file and return if cached_file?
    @document = Document.public.find_by_path(params[:path].join('/'))
    raise ActiveRecord::RecordNotFound if @document.nil?

 
    @documents = @document.archive_for(params[:month], params[:year]).paginate :page => params[:page], :per_page => Settings.documents.per_page
    render :template => view_for(:suffix => '_archive')
    cache_this_page!
  end

  # Allows searching of pages in a folder
  # /:permalink/search?search[title_like]=hello
  def search
    params[:search] ||= {}
    @document = Document.public.find_by_path(params[:path].join('/'))
    params[:search].merge!(:parent_id => @document.id)
    params[:search][:state_eq] = 'published'
    @documents = Document.search(params[:search]).paginate :page => params[:page], :per_page => Settings.documents.per_page
    setup_view_environment
    render :template => view_for(:suffix => '_search')
  end

  # Allow Document wide search
  # /search?terms[title_like]=hello
  def search_all
    params[:search] ||= {}
    params[:search][:state_eq] = 'published'
    @documents = Document.search(params[:search]).paginate :page => params[:page], :per_page => Settings.documents.per_page
    render :template => '/pages/search'
  end

  # public facing creation of documents
  def create
    @document = Document.public.find(params[:id])

    begin
      do_human_test
    rescue
      flash.now[:notice] = 'You did not add up the numbers correctly, please try again.'

      new_document = Document.new
      new_document.body = params[:document][:body]

      eval("@new_#{params[:label]} = new_document")

      setup_view_environment
      render :template => view_for
      return
    end

    params[:document][:state] = nil # prevent auto approval hack (FIXME: use attr_protected)


    if @document.meta_definition_for(params[:label]).allowed? current_user, 'create'

      new_document = Document.new(params[:document])
      new_document.parent = @document
      new_document.label = params[:label]
      new_document.author = current_user || User.anonymous
      new_document.published_at = Time.now

      if new_document.save
        flash[:notice] = new_document.meta_definition.flash_messages['create'] || "Your #{params[:label]} has been saved"
        if new_document.meta_definition.notify_admins
          DocumentMailer.deliver_new_document(new_document)
        end
        redirect_to document_path(@document)
      else
        flash.now[:notice] = 'Could not be saved'
        eval("@new_#{params[:label]} = new_document")
        setup_view_environment
        render :template => view_for
      end
    else
      render :text => 'Not Allowed' and return
    end
  end
  
  private

  def request_path
    @path ||= CGI::unescape(request.path[1..-1])
    @path.blank? ? 'home' : @path
  end

  # Does a cache exist for this URL
  def cached_file?
    Settings.documents.page_cache && File.exists?(cache_file)
  end

  def cache_file
    @url_id ||= request_path.split('/').last + (request.query_string.blank? ? '' : '_' + Digest::MD5.hexdigest(request.query_string))
    @cache_file ||= File.join(RAILS_ROOT, 'public', 'cache', request_path, self.action_name, @url_id) + '.html'
  end

  def cache_this_page!
    if Settings.documents.page_cache && !File.exists?(cache_file)
      logger.debug 'Caching Page: ' + cache_file
      FileUtils.mkdir_p File.dirname(cache_file)
      cache = File.open(cache_file, 'w')
      cache.write(response.body)
      cache.close
    end
  end

  def do_human_test
    raise 'Human Test Failed' unless params[:human_test][:answer].crypt('humAn5') == params[:human_test][:crypted_answer]
  end

  def setup_view_environment
    # create children vars such as @comments
    if @document.can_have_children?
      
      @children = []
      
      # make an instance variable for each child eg. @posts @comments etc.
      @document.child_labels.each do | label|
        per_page = @document.meta_definition.children.by_label(label).first.per_page || Settings.documents.per_page
        order = @document.meta_definition.children.by_label(label).first.sort_by || Settings.documents._sort_by
        instance_variable_set('@' + label.pluralize, @document.children.by_label(label).with_states(:published).paginate(:order => order, :page => params[:page], :per_page => per_page))
      end
      
    end
   
    # make instance variable for the parent eg. @story
    instance_variable_set("@#{@document.label.gsub(' ', '_')}", @document)
   
    # HTML meta tags
    @page_title = @document.meta_title
    @meta_description = @document.meta_description
    @meta_keywords = @document.meta_keywords
  end


  # eg. blog.post.comment.html.erb
  def view_for(options = {})
    create_missing_template if !params[:create_template].nil? && RAILS_ENV == 'development'
    
    options[:extension] = '.html.erb'
    options[:prefix] ||= ''
    options[:suffix] ||= ''

    filenames = [@document.permalink, @document.meta_definition.template_filename(false), 'default']
    
    view_paths.each do | view_path |
      filenames.each do | filename |      
        target = File.join('pages', filename) + options[:suffix] + options[:extension]
        target_with_view_path = File.join(view_path, target)
        if File.exists? target_with_view_path
          logger.debug 'FOUND: ' + target_with_view_path
          return target
        else
          logger.debug 'NOT FOUND: ' + target_with_view_path
        end
      end
    end
    raise 'No Template found'
  end
end
