require 'rbbt/util/misc'

require 'sinatra/base'

module Sinatra
  module RbbtAuth

    module Helpers
      def authorized?
        session[:authorized]
      end

      def authorize!
        return true if authorized?
        target_url = request.env["REQUEST_URI"]
        Log.warn("Unauthorized access to #{target_url}")
        session[:target_url] = target_url
        redirect '/login' 
      end

      def logout!
        session[:authorized] = false
      end

      def user
        session[:user]
      end
    end

    def self.registered(app)
      app.helpers RbbtAuth::Helpers

      if Rbbt.etc.web_users.exists?
        app.set :users, Rbbt.etc.web_users.yaml
      else
        app.set :users, {}
      end

      app.get '/login' do
        "<form class='login' method='POST' action='/login'>" +
          "<label for='login_name'>Name: </label>" +
          "<input id='login_name' type='text' name='user'>" +
          "<label for='login_pass'>Pass: </label>" +
          "<input id 'login_pass' type='password' name='pass'>" +
          "<input type='submit'>" +
        "</form>"
      end

      app.post '/login' do
        user = params[:user]
        pass = params[:pass]

        if settings.users.include?(user) and settings.users[user] == pass
          Log.warn("Successful login #{[user, pass] * ": "}")
          session[:authorized] = true
          session[:user] = user
          if session[:target_url]
            url = session.delete :target_url
            redirect url
          else
            redirect '/'
          end
        else
          Log.warn("Failed login attempt #{[user, pass] * ": "}")
          session[:authorized] = false
          redirect '/login'
        end
      end
    end
  end

end
