default_run_options[:pty] = true

set :port, 29209
set :use_sudo, :false

set :application, "siphon"
set :repository,  "git://github.com/jpbougie/siphon.git"

set :scm, "git"
set :user, "siphon"
set :branch, "master"

set :deploy_to, "/var/www/#{application}"
set :config_home, "/home/siphon/config"

role :app, "jpbougie.net"
role :web, "jpbougie.net"
role :db,  "jpbougie.net", :primary => true

namespace :deploy do
    task :after_symlink, :role => :app do
      run "ln -sf #{shared_path}/siphon_prod.db #{current_path}/siphon_prod.db"
    end
    
    after :symlink, :link_configuration
    
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "merb -d --fast-deploy -e production -m #{current_path} -c 1 -p 5000 -P #{shared_path}/pids/siphon.%s.pid -u siphon -G siphon"
    end
    
    task :stop, :roles => :app do
      run "merb -K all -d -e production -m #{current_path} -c 1 -p 5000 -P #{shared_path}/pids/siphon.%s.pid -u siphon -G siphon"
    end
end