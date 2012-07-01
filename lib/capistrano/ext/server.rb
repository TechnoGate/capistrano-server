require 'capistrano/ext/helpers'
require 'capistrano/ext/rsa'
require 'capistrano/ext/web_server'

unless Capistrano::Configuration.respond_to?(:instance)
  abort 'capistrano/ext/server requires capistrano 2'
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :setup do
        desc 'Prepare the server (database server, web server and folders)'
        task :default, :roles => [:app, :db, :web] do
          # Empty task, server preparation goes into callbacks
        end

        task :finish do
          # Empty task for callbacks
        end
      end
    end
  end

  after 'deploy:server:setup', 'deploy:server:web_server:setup'
end
