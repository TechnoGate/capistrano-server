# encoding: utf-8

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort 'capistrano/ext/nginx requires capistrano 2'
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        namespace :nginx do

          _cset :nginx_init_path, "/etc/init.d/nginx"

          desc "[internal] Generate Nginx configuration"
          task :configuration, :roles => :web, :except => { :no_release => true } do
            template = File.read File.expand_path('../../../templates/nginx.conf.erb', __FILE__)

            nginx = OpenStruct.new
            nginx.listen_port      = fetch :web_server_listen_port, 80
            nginx.application_url  = fetch :application_url
            nginx.indexes          = fetch :web_server_indexes, %w(index.php index.html)
            nginx.denied_access    = fetch :denied_access, %w(.htaccess /system/logs)
            nginx.auth_file        = fetch :web_server_auth_file, nil
            nginx.auth_credentials = fetch :web_server_auth_credentials, nil
            nginx.rewrite          = fetch :web_server_mod_rewrite, true
            nginx.php_fpm_host     = fetch :php_fpm_host, 'localhost'
            nginx.php_fpm_port     = fetch :php_fpm_port, '9000'
            nginx.logs_path        = fetch :logs_path
            nginx.public_path      = fetch :public_path

            write ERB.new(template).result(binding),
              fetch(:web_conf_file),
              use_sudo: true
          end

          desc "Start nginx web server"
          task :start, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} start
            CMD
          end

          desc "Stop nginx web server"
          task :stop, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} stop
            CMD
          end

          desc "Restart nginx web server"
          task :restart, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} restart
            CMD
          end

          desc "Resload nginx web server"
          task :reload, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} reload
            CMD
          end

        end
      end
    end
  end
end
