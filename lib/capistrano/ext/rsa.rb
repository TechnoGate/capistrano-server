unless Capistrano::Configuration.respond_to?(:instance)
  abort 'capistrano/ext/contao requires capistrano 2'
end

Capistrano::Configuration.instance(:must_exist).load do
  desc 'Send SSH key to the server'
  task :scp_rsa, :roles => [:app, :web, :db] do
    rsa = "#{ENV['HOME']}/.ssh/id_rsa.pub"

    begin
      run <<-CMD
            mkdir -p ~/.ssh; \
            touch ~/.ssh/authorized_keys; \
            echo '#{File.read rsa}' >> ~/.ssh/authorized_keys;
      CMD
    rescue Capistrano::CommandError
      logger.import 'Cannot send the SSH key to the server'
      abort 'Cannot send the SSH key to the server'
    end
  end
end
