class DocumentMailer < ActionMailer::Base
  
  def new_document(document)
    subject "[#{Settings.site.name}] New #{document.label}"
    from  Settings.mailer.from
    recipients User.all.select { |u| u.has_role? 'admin'}.collect { |u| u.email }.join(', ')
    body  :document => document
    content_type "text/html"
  end



end
