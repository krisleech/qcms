class MetaDefinition < ActiveRecord::Base
  has_many :documents, :dependent => :destroy

  validates_presence_of :label_path, :label
  validates_uniqueness_of :label_path

  acts_as_list
  acts_as_tree
  path_finder :uid => 'label', :column => 'label_path'

  default_scope :order => 'position DESC'

  named_scope :by_label, lambda { |label| { :conditions => ['label = ?', label] } }

  before_save :nullify_empty_columns

  serialize :autherisation, Hash
  serialize :field_map, Hash
  serialize :flash_messages, Hash

  
  def autherisation
    super || {}
  end

  def field_map
    super || {}
  end

  def flash_messages
    super || {}
  end
  

  def allowed?(user, action)
    tokens = (autherisation[action] || Settings.documents.autherisation.send(action)).split(' ')
    tokens.each do | token |
      return true if token == 'all'
      return true if token == 'author' && self.author == user
      return true if user.has_role? token
    end
    false
  end

  # Used to find template named after label_path
  # eg. blog.post.html.erb
  def template_filename(include_extension = true)
    label_path.gsub('/', '.') + (include_extension ? '.html.erb' : '')
  end

  private

  # Prevent empty strings being saved
  def nullify_empty_columns
    %w(sort_by per_page).each { |column| self.send(column+'=', nil) if self.send(column) == '' }
  end
end
