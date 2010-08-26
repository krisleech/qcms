class Sendmail < ActionMailer::Base
  
  def form(params, meta, template)
    subject meta[:subject]
    from  set_from(params, meta)
    recipients meta[:recipients]
    body  :data => params
    content_type "text/html"
    template template
  end

  private

  def set_from(params, meta)
    params[:email].nil? ? params[:email] : meta[:from]
  end

end
