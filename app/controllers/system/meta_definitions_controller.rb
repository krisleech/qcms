class System::MetaDefinitionsController < System::SystemController
  inherit_resources
  respond_to :html

  def index
    @meta_definitions = MetaDefinition.roots
    @meta_definition = MetaDefinition.new
  end

  def update
    update! { system_meta_definitions_path }
  end

  def create
    create! { system_meta_definitions_path }
  end

  def up
    @meta_definition = MetaDefinition.find(params[:id])
    @meta_definition.move_higher
    redirect_to system_meta_definitions_path
  end

  def down
    @meta_definition = MetaDefinition.find(params[:id])
    @meta_definition.move_lower
    redirect_to system_meta_definitions_path
  end
end
