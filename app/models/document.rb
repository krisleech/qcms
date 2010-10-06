class Document < ActiveRecord::Base
  acts_as_tree
  path_finder :uid => 'permalink'
 
  acts_as_list :scope => :parent
  
  # Allow lists to be independant when grouping by type 
  # acts_as_list :scope => 'parent_id = #{parent_id} and type = \'#{type}\''

  self.skip_time_zone_conversion_for_attributes = [] # FIX BUG: https://rails.lighthouseapp.com/projects/8994/tickets/1339-arbase-should-not-be-nuking-its-children-just-because-it-lost-interest
  
  has_attached_file :resource,
    :styles => { :medium => "300x300>", :thumb => "100x100>" },
    :url => "/files/document/:id/:style.:extension",
    :path => ":rails_root/public/files/document/:id/:style.:extension",
    :whiny_thumbnails => false # allow non-images to be uploaded

  # Prevent "not recognized by the 'identify' command" error for non-images
  before_post_process :resource_image?
  def resource_image?
    !(resource_content_type =~ /^image.*/).nil?
  end

  # Settings this to true or '1' will remove the resource
  attr_accessor :delete_resource  

  # Assosiations
  belongs_to  :author,  :class_name => 'User', :foreign_key => 'author_id'
  belongs_to  :meta_definition

  # Scopes 
  named_scope :recent, lambda { { :conditions => ['created_at > ?', 1.week.ago] } }
  named_scope :latest, { :order => 'updated_at DESC' }
  named_scope :published_between, lambda {|start_date, end_date| { :conditions => {:published_at => start_date..end_date } } }
  named_scope :order_by, lambda { |order| { :order => order } }
  named_scope :by_label, lambda { |label| { :conditions => { :label => label }, :include => [:meta_definition, :parent, :author] } }
  named_scope :only, lambda { |limit| { :limit => limit } }
  named_scope :roots, { :conditions => { :parent_id => nil }, :include => [:meta_definition, :parent] }
  named_scope :public, { :conditions => { :state => 'published' }}
  named_scope :offset, lambda { |offset| { :offset => offset } }

  # Callbacks
  before_validation_on_create :pull_meta_definition
  before_validation_on_create :auto_populate
  before_save  :generate_summary, :set_meta_data, :sanatize_body
  before_save :clear_resource # better name?
  after_save  :touch_parent
  before_save  :copy_permalink_to_path

  # Validations
  validates_presence_of :state, :author_id, :type, :label, :meta_definition_id
  validates_presence_of :published_at, :if => proc { |d| d.published? }
  validates_uniqueness_of :path  

  # States
  state_machine :attribute => :state, :initial => :draft do
    event :publish do
      transition :draft => :published
    end

    event :unpublish do
      transition :published => :draft
    end
    
    state :private, :system, :pending

    after_transition :on => :published do |document, transition|
      document.published_at = Time.now unless document.published_at      
    end
  end

  # autherisation
  def allowed?(user, action)
    meta_definition.allowed?(user, action)
  end

  def meta_definition_for(label)
    meta_definition.children.by_label(label).first
  end
 
  def module_name
    self.root.permalink.titleize
  end

  def permalink    
    create_permalink if read_attribute(:permalink).blank?
    read_attribute(:permalink)
  end

  # Rails support
  def to_param
    path
  end

  # allow Document['homepage']
  def self.[](path)
    find_by_path(path)
  end

  # All children grouped by year and month
  def archive
    result = ActiveSupport::OrderedHash.new
    children.public.group_by(&:year).sort { |a,b| b <=> a }.each do | year, posts |
      result[year] = ActiveSupport::OrderedHash.new
      grouped_posts = posts.group_by(&:month_num)
      (1..12).each do | month |
        result[year][month] = grouped_posts[month] || []
      end
    end
    result
  end

  # children for month and year
  def archive_for(month, year)    
    from_date = Time.parse("#{month}/01/#{year}") # mm/dd/yy
    to_date = from_date.end_of_month
    children.public.published_between(from_date, to_date).order_by('published_at DESC')
  end

  # Never return nil
  # FIXME: use database default value
  def body
    read_attribute(:body) || ''
  end

  # Types of children this document can have
  def child_labels
    self.meta_definition.children.map { |c| c.label }
  end

  def can_have_children?
    !self.meta_definition.children.empty?
  end
 
  def image
    self.resource
  end

  def image_description
    self.resource_description
  end
 
  def attachment
    self.resource
  end
 
  # Used for grouping
  # FIXME: put in module eg. date_groupable :column => 'published_at'
  def week
    published_at.strftime('%W')
  end

  def day
    published_at.strftime('%d')
  end

  def month
    published_at.strftime('%B')
  end

  def month_num
    published_at.month
  end

  def year
    published_at.strftime('%Y')
  end

  def month_year
    published_at.strftime('%B %Y')
  end

  # Note: The standard ActiveRecord#exists? only fetches the id field so
  # the add_assosiations (after_find) fails due to use of assosiations
  def self.exists?(conditions)
    self.find(:first, :conditions => conditions)
  end

  # after_find can only be called like this
  def after_find
    add_assosiations
    map_fields
  end

  SortByOptions = {
          'Date DESC' => 'published_at DESC',
          'Date ASC'  => 'published_at ASC',
          'Title'     => 'title',
          'Manually'  => 'position ASC'
        }

  PerPageOptions = [1, 5, 10, 20, 50, 100]

  private

  # make sure the last element of the path is the same as the permalink
  def copy_permalink_to_path
    self.path = (self.path.split('/')[0..-2] + [self.permalink]).join('/')  
  end

  # This will trigger a touch all they way to root
  # after_save
  def touch_parent
    self.parent.touch if parent
  end

  # before_validation_on_create
  def pull_meta_definition
    return if root?
    self.meta_definition = self.parent.meta_definition.children.by_label(label).first
    raise "No Meta Definition found for label [#{self.label}] in parents children. Choices are [#{self.parent.meta_definition.children.map { |md| md.label }.join(', ') }]" if self.meta_definition.nil?

    # Enforced values
    self.label = self.meta_definition.label # cache label to reduce sql calls
    
    # Defaults values
    self.type ||= self.meta_definition.default_type || 'Document'
    self.state ||= self.meta_definition.default_state || 'draft'
  end

  # Alias children and parent eg. @post.comments and @comment.post
  # Note they are scope to a published state
  def add_assosiations    
    self.child_labels.each do | label |   
      self.class.send(:define_method, label.pluralize) { self.children.with_state(:published).by_label(label) }
    end

    if self.parent
      self.class.send(:define_method, self.parent.label) { self.parent } 
    end
  end

  def map_fields
    meta_definition.field_map.each do | source , target |
      self.class.send(:define_method, source) { send(target) }
    end
  end

  # before_validation_on_create
  def auto_populate
    create_permalink
    generate_summary
    set_meta_data    
  end

  def generate_summary
    self.summary = Sanitize.clean(self.body).to(255) if self.summary.blank?
  end

  def set_meta_data    
    self.meta_title = self.title.to(255) if self.meta_title.blank?
    self.meta_description = self.summary.to(255) if self.meta_description.blank?
  end

  # before_save
  def sanatize_body
    if self.meta_definition.body_strip_html?
      self.body = Sanitize.clean(self.body)
    end
    
    unless self.meta_definition.body_length.blank?
      self.body = self.body.to(self.meta_definition.body_length)
    end
  end

  # TODO: Refactor in to a module
  def create_permalink(separator = '_', max_size = 127)
    pull_meta_definition if self.meta_definition.nil?
   
    unless self.meta_definition.randomise_permalink?
      return '' if title.blank?
      # words to ignore, usually the same words ignored by search engines
      ignore_words = ['a', 'an', 'the', '?']
      ignore_re = String.new
      # building ignore regexp
      ignore_words.each { |word|
        ignore_re << word + '\b|\b'
      }
      ignore_re = '\b' + ignore_re + '\b'      
      new_permalink = self.title.dup.gsub("'", separator)      
      new_permalink.gsub!(ignore_re, '')      
      new_permalink.downcase!
      new_permalink.strip!      
      new_permalink.gsub!(/[^a-z0-9]+/, separator)      
      new_permalink = new_permalink.to(max_size)      
      new_permalink.gsub!(/^\\#{separator}+|\\#{separator}+$/, '')
    else
      new_permalink = ActiveSupport::SecureRandom.hex(16)
    end
   
    write_attribute(:permalink, new_permalink)
  end

  # before_save
  # '1' is for compatibility with form inputs
  def clear_resource
    if self.delete_resource && (self.delete_resource == '1' || self.delete_resource == true)
      self.resource = nil
    end
  end
end
