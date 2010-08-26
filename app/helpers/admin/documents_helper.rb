module Admin::DocumentsHelper

  # returns options Array for 'sort_by' select
  def sort_by_options
    options = { 'Date DESC' => 'published_at DESC',
                'Date ASC'  => 'published_at ASC',
                'Title'     => 'title',
                'Manually'  => 'position ASC'
        }
    
    result = []        
    options.each do |k,v|
      k = k + ' (Default)' if v == Settings.documents._sort_by
      result << [k,v]
    end
 
    result.sort       
  end
  
  # Returns options Array for 'per_page' select 
  def per_page_options
    options = [1, 5, 10, 20, 50, 100]
    result = []
    options.each do | o |
      k = o.to_s
      v = o
      k = k + ' (Default)' if o == Settings.documents.per_page
      result << [k, v]
    end
    result
  end

  # Find the correct form partial for @document
  def form_partial
    file = "admin/documents/_#{@document.label}_form.html.erb"
    self.view_paths.each do | view_path |      
      target = File.join(view_path, file)
      logger.debug 'PARTIAL ' + target
      if File.exists? target
        return file.gsub('/_', '/')
      end
    end
    "admin/documents/form"    
  end
  
  def admin_bread_crumb(document, root = true)
    result = ''
    if root
      result << '<ul class="bread_crumb">'
      result << "<li><a href='#{admin_documents_path}'>Dashboard</a></li>"
    end
    if document
      result << admin_bread_crumb(document.parent, false) if document.parent
      unless document.new_record? # no title yet
        result << '<li>'
        result << (root ? (document.title || document.permalink) : link_to(document.permalink.titleize, admin_document_path(document.id)))
        result << '</li>'
      end
    end
    result << '</ul>' if root
    result
  end
  
  def admin_cancel_document_path(document)
    if document.parent
      admin_document_path(document.parent.id)
    else
      admin_dashboard_path
    end
  end
end
