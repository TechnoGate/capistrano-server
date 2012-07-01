require 'capistrano/ext/nginx'

unless Capistrano::Configuration.respond_to?(:instance)
  abort 'capistrano/ext/web_server requires capistrano 2'
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        desc "Prepare the web server"
        task :setup, :roles => :web, :except => { :no_release => true } do
          # Empty task, server preparation goes into callbacks
        end

        task :finish, :roles => :web, :except => { :no_release => true } do
          # Empty task, server preparation goes into callbacks
        end

        desc '[internal] Setup folders'
        task :folders, :roles => :web do
          sudo <<-CMD
            mkdir -p #{File.dirname fetch(:web_conf_file)} #{File.dirname fetch(:web_server_auth_file, '')}
          CMD
        end

        desc "[internal] Generate Web configuration"
        task :configuration, :roles => :web, :except => { :no_release => true } do
          case fetch(:web_server_app)
          when :nginx
            find_and_execute_task 'deploy:server:web_server:nginx:configuration'
          else
            abort "I don't know how to build '#{web_server_app}' configuration."
          end
        end

        desc "[internal] Generate authentification"
        task :authentification, :roles => :web, :except => { :no_release => true } do
          if exists?(:web_server_auth_credentials)
            content = Array.new
            unencrypted_content = Array.new

            fetch(:web_server_auth_credentials).each do |credentials|
              if credentials[:password].respond_to?(:call)
                password = credentials[:password].call
              else
                password = credentials[:password]
              end

              unencrypted_content << "#{credentials[:user]}:#{password}"
              content << "#{credentials[:user]}:#{password.crypt(gen_pass(8))}"
            end

            # Write the encrypted content
            write content.join("\n"),
              fetch(:web_server_auth_file),
              use_sudo: true

            # Write the unencrypted content
            write unencrypted_content.join("\n"),
              "#{fetch :deploy_to}/.http_basic_auth"

            logger.info "This site uses http basic auth, the credentials are:"
            unencrypted_content.each do |m|
              logger.trace "username: #{m.split(':').first.chomp} password: #{m.split(':').last.chomp}"
            end
          end
        end

        desc "print authentification file"
        task :print_http_auth, :roles => :web, :except => { :no_release => true } do
          read("#{fetch :deploy_to}/.http_basic_auth").split("\n").each do |m|
            logger.trace "username: #{m.split(':').first.chomp} password: #{m.split(':').last.chomp}"
          end
        end
      end
    end
  end

  # Internal Dependencies
  before 'deploy:server:web_server:configuration', 'deploy:server:web_server:folders'
  before 'deploy:server:web_server:configuration', 'deploy:server:web_server:authentification'
  before 'deploy:server:web_server:setup', 'deploy:server:web_server:configuration'
  after  'deploy:server:web_server:setup', 'deploy:server:web_server:finish'
end
