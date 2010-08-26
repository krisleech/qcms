class Admin::AdminController < ApplicationController
  before_filter :require_user

  layout 'admin'

  def system    
  end

  def dashboard
    redirect_to admin_documents_path
  end
end
