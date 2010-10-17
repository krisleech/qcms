# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{qcms}
  s.version = "1.3.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kris Leech"]
  s.date = %q{2010-10-17}
  s.description = %q{Key CMS features: extended template pathing, sitemap.yml, simple configurable, deeply nestable content}
  s.email = %q{kris.leech@interkonect.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "README",
     "Rakefile",
     "VERSION",
     "app/controllers/admin/admin_controller.rb",
     "app/controllers/admin/documents_controller.rb",
     "app/controllers/admin/meta_definitions_controller.rb",
     "app/controllers/documents_controller.rb",
     "app/controllers/sendmail_controller.rb",
     "app/controllers/system/meta_definitions_controller.rb",
     "app/controllers/system/system_controller.rb",
     "app/helpers/admin/documents_helper.rb",
     "app/helpers/documents_helper.rb",
     "app/helpers/sendmail_helper.rb",
     "app/helpers/system/documents_helper.rb",
     "app/models/document.rb",
     "app/models/document_mailer.rb",
     "app/models/document_sweeper.rb",
     "app/models/meta_definition.rb",
     "app/models/sendmail.rb",
     "app/views/admin/documents/_form.html.erb",
     "app/views/admin/documents/default.edit.html.erb",
     "app/views/admin/documents/default.new.html.erb",
     "app/views/admin/documents/default.show.html.erb",
     "app/views/admin/documents/index.html.erb",
     "app/views/admin/documents/shared/_resource_link.html.erb",
     "app/views/document_mailer/new_document.erb",
     "app/views/layouts/admin.html.erb",
     "app/views/layouts/application.html.erb",
     "app/views/layouts/system.html.erb",
     "app/views/pages/404.html.erb",
     "app/views/pages/contact.html.erb",
     "app/views/pages/default.html.erb",
     "app/views/pages/feed.rss.builder",
     "app/views/pages/home.html.erb",
     "app/views/pages/search.html.erb",
     "app/views/pages/shared/_archived_pages.erb",
     "app/views/pages/shared/_related_pages.html.erb",
     "app/views/pages/sitemap.html.erb",
     "app/views/pages/template.erb",
     "app/views/pages/thank_you.html.erb",
     "app/views/sendmail/default.erb",
     "app/views/system/meta_definitions/_form.html.erb",
     "app/views/system/meta_definitions/_meta_definition.html.erb",
     "app/views/system/meta_definitions/edit.html.erb",
     "app/views/system/meta_definitions/index.html.erb",
     "app/views/system/meta_definitions/new.html.erb",
     "app/views/system/system/dashboard.html.erb",
     "config/sitemap.example.yml",
     "db/migrate/20090824150210_create_documents.rb",
     "db/migrate/20091208124512_create_meta_definition.rb",
     "init.rb",
     "install.rb",
     "lib/qcms.rb",
     "qcms.gemspec",
     "rails/init.rb",
     "test/qwerty_test.rb",
     "test/test_helper.rb",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/krisleech/qcms}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A CMS built in collaberation with designers}
  s.test_files = [
    "test/qwerty_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
