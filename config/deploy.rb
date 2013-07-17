set :application, "openlibrary"
set :repository, "git://github.com/siliconsenthil/openlibrary.git"
set :user, "root"
set :scm, :git

begin
  server_ip = {chennai: "10.10.4.50", pune: "10.10.5.121"}.find{|o, ip| o.to_s.downcase == office.downcase}.last
  role :web, server_ip # Your HTTP server, Apache/etc
  role :app, server_ip# This may be the same as your `Web` server
  role :db, server_ip, :primary => true # This is where Rails migrations will run
rescue NameError
  puts "Usage: cap -S office=<Chennai|Pune> <task>"
  exit
end

default_run_options[:pty] = true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && passenger start -p80 -d"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && passenger stop --pid-file tmp/pids/passenger.80.pid"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end
end

namespace :bundler do
  task :install, :roles => :app do
    run "cd #{release_path} && bundle install --binstubs --without=development test"
  end
end

#before 'deploy:update_code', 'deploy:stop'
after 'deploy:update_code', 'bundler:install'

