class System::SystemController < ApplicationController
  unloadable
  before_filter :require_user

  layout 'system'

  def dashboard
  end
end
