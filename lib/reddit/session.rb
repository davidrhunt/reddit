module Reddit
  BASE_URL = "http://www.reddit.com/"
  PROFILE_URL = BASE_URL + "user/[username]/"
  SUBREDDIT_URL = BASE_URL + "r/[subreddit]/"
  COMMENTS_URL = BASE_URL + "comments/[id]/"
  
  # raised when attempting to interact with a subreddit that doesn't exist.
  class SubredditNotFound < StandardError; end
  
  # raised when attempting to interact with a profile that doesn't exist.
  class ProfileNotFound < StandardError; end
  
  # raised when attempting to log in with incorrect credentials.
  class AuthenticationException < StandardError; end
  
  # A reddit browsing session.
  class Session
    
    # initialize the session with a username and password.  Currently not used.
    def initialize(username = "", password = "")
      @username = username
      @password = password
      @logged_in = false
    end
    
    # return the main reddit.
    def main
      return Reddit.new()
    end
    
    # return a specific subreddit.
    def subreddit(subreddit)
      return Reddit.new(subreddit)
    end
    
    # return a specific user's page.
    def user(username)
      return User.new(username)
    end
    
    def logged_in?
      @logged_in
    end
    
    def login
      url = "http://www.reddit.com/api/login.json"
      params = { 'reason' => '', 'op' => 'login-main', 'dest' => '/', 'user_login' => @username, 'passwd_login' => @password, 'rem' => '1' }
      result = Net::HTTP.post_form(URI.parse(url), params)
      resources = JSON.parse(result.body, :max_nesting => 0)
      if resources['error']
        raise AuthenticationException, resources['error']['message']
      end
      pp resources
      return true
    end
  end
end
