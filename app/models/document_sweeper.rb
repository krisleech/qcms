class DocumentSweeper < ActionController::Caching::Sweeper
  observe Document

  def after_save(document)
    clear_document_cache(document)
  end

  def after_destroy(document)
    clear_document_cache(document)
  end

  # We dont need to expire the cache for the parent as a document always
  # touches its parent after_save, which will cause this method to be run
  # for the parent as well.
  
  def clear_document_cache(document)        
    expire_fragment :recent_posts
    expire_fragment :menu

    cache_paths = []
    cache_paths << File.join(RAILS_ROOT, 'public', 'cache', document.path)

    cache_paths.each do | cache_path |
      Rails.logger.debug 'Deleting CACHE: ' + cache_path
      FileUtils.rm_rf cache_path if File.exists? cache_path
    end
  end
end