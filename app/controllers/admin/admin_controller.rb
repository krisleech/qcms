class Admin::AdminController < ApplicationController
  before_filter :require_user

  layout 'admin'

  def dashboard
    redirect_to admin_documents_path
  end
end
