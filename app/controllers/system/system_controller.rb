class System::SystemController < ApplicationController
  before_filter :require_user

  layout 'system'

  def dashboard
  end
end
