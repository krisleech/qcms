module DocumentsHelper

  def related_pages(heading=nil)
    render :partial => 'pages/shared/related_pages', :locals => { :heading => heading }
  end

  def archived_pages(heading=nil)
    render :partial => 'pages/shared/archived_pages', :locals => { :heading => heading }
  end

  def bread_crumb(document)
    result = '<ul class="bread_crumb">'
    if document.parent
      result = bread_crumb(document.parent)      
    end
    result << '<li>' + link_to(document.title, document_path(document)) + '</li>'
    result << '</ul>'
    result
  end

#  def archive_date
#    if showing_archive?
#      "#{Date::MONTHNAMES[params[:month].to_i]} #{params[:year]}"
#    end
#  end
#
#  def showing_archive?
#    params[:month] && params[:year]
#  end
end
