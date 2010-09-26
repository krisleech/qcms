class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string   "title"
      t.string   "type"
      t.text     "summary"
      t.text     "body"
      t.string   "permalink"
      t.string   "state"
      t.string   "url"
      t.string   "label"
      t.text     "path"
      t.integer  "author_id"
      t.integer  "parent_id"
      t.string   "meta_title"
      t.string   "meta_description"
      t.string   "meta_keywords"
      t.integer  "position", :default => 0
      t.string   "resource_file_name"
      t.string   "resource_content_type"
      t.integer  "resource_file_size"
      t.string   "resource_description"
      t.datetime "published_at"
      t.integer  "meta_definition_id"
      t.integer  "hits", :default => 0
      # Extra fields
      t.text     "cf_text_1"
      t.string   "cf_string_1"
      t.string   "cf_string_2"

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
