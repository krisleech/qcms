class SendmailController < ApplicationController
  unloadable
  
  def deliver
    if has_required_fields
      meta = params[:meta]

      if recipients_valid(meta[:recipients])
        
        template = view_for([params[:form], 'default'], 'sendmail', '.erb')
        
        Sendmail.deliver_form(sanatize_params(params), meta, template)

        # After deliver options (redirect, show flash message or render template)        
        if meta[:redirect_to]
          flash[:notice] = meta[:message] if meta[:message]
          redirect_to meta[:redirect_to] and return
        end

        if meta[:message]
          flash[:notice] = meta[:message]
          redirect_to root_url
        end

        if meta[:show_page]
          render :template => File.join('pages', meta[:show_page]) + '.html.erb' and return
        end
      else
        render :text => 'Error: Recipient not in white list'
      end
    else
      render :text => 'Error: Required Field Missing'
    end
  end

  private


    def view_for(filenames, suffix = '', prefix = '.html.erb')
      filenames.each do | filename |
        next if filename.nil?
        self.view_paths.each do |path|
          target = (File.join(path.to_s, suffix, filename.to_s) + prefix).downcase
          logger.debug 'Looking: ' + target
          if File.file? target
            logger.debug 'Template CHOOSEN: ' + target
            return filename
          end
        end
      end
      logger.debug 'NO TEMPLATE FOUND!!'
      nil
    end



  # Anti SPAM detection
  def recipients_valid(recipients)
    recipients.split(',').each do |r|
      unless Settings.forms.recipients.include? r.strip
        logger.warn('Email Address not in white list: ' + r)
        return false
      end
    end

  end

  def has_required_fields
    required_fields = ['recipients', 'subject']
    required_fields.each do |f|
      unless params[:meta][f]
        logger.debug 'Missing form field ' + f
        return false
      end
    end
  end

  def sanatize_params(params)
    black_list = ['meta', 'authenticity_token', 'id', 'controller', 'action', 'send', 'submit', 'form']
    white_list = []
    params.delete_if { |k,v| black_list.include? k.downcase }
    params.each do |k,v|
      params[k] = Sanitize.clean(v) unless white_list.include? k.downcase
    end
    params
  end
end
