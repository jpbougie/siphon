# Go to http://wiki.merbivore.com/pages/init-rb

#use_orm :datamapper
use_test :rspec
use_template_engine :haml


merb_gems_version = "1.0.11"
dm_gems_version   = "0.9.11"
do_gems_version   = "0.9.11"

dependency "merb-core", merb_gems_version 
dependency "merb-assets", merb_gems_version  
dependency "merb-action-args", merb_gems_version
dependency "merb-helpers", merb_gems_version 
dependency "merb-haml", merb_gems_version

dependency "dm-core", dm_gems_version
dependency "dm-is-state_machine", dm_gems_version
dependency "dm-serializer", dm_gems_version
dependency "dm-aggregates", dm_gems_version
dependency "data_objects", do_gems_version
dependency "merb_datamapper", merb_gems_version
dependency "do_sqlite3", do_gems_version
dependency "mperham-memcache-client", :require_as => "memcache"
dependency "jpbougie-couchrest", :require_as => "couchrest"

dependency "httparty"

Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
end

# Move this to application.rb if you want it to be reloadable in dev mode.
Merb::Router.prepare do
  match('/').to(:controller => "siphon", :action =>'index')
  match('/accepted').to(:controller => "siphon", :action => 'accepted')
  match('/load').to(:controller => "siphon", :action =>'load')
  match('/accept').to(:controller => "siphon", :action =>'accept')
  match('/reject').to(:controller => "siphon", :action =>'reject')
  match('/couch/:id').to(:controller => "siphon", :action => 'couch')

  default_routes
end

Merb::Config.use { |c|
  c[:environment]         = 'production',
  c[:framework]           = {},
  c[:log_level]           = :debug,
  c[:log_stream]          = STDOUT,
  # or use file for logging:
  # c[:log_file]          = Merb.root / "log" / "merb.log",
  c[:use_mutex]           = false,
  c[:session_store]       = 'cookie',
  c[:session_id_key]      = '_siphon_session_id',
  c[:session_secret_key]  = '5fd4a70d2e0e76414744b84a59eb63ba91b0582a',
  c[:exception_details]   = true,
  c[:reload_classes]      = true,
  c[:reload_templates]    = true,
  c[:reload_time]         = 0.5
  
  c[:yahoo_appid]         = "S.EKKvHV34EBy7AKc6Mpq.YsBOAUAHcjh4jzLSRI2IasyjPzN7EAasgcEZ2tYR2H"
  c[:queue]               = "jpbougie.net:22133"
  c[:couchdb]             = "http://couch.jpbougie.net/parsing"
}
