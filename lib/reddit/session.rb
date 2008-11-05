module Reddit
  BASE_URL = "http://www.reddit.com/"
  PROFILE_URL = BASE_URL + "user/[username]/"
  SUBREDDIT_URL = BASE_URL + "r/[subreddit]/"
  COMMENTS_URL = BASE_URL + "comments/[id]/"
  
  LOGIN_URL = BASE_URL + "api/login.json"
  INFO_URL = BASE_URL + "api/info.json?count=1&url=[url]"
  VOTE_URL = BASE_URL + "api/vote.json"
  
  # raised when attempting to interact with a subreddit that doesn't exist.
  class SubredditNotFound < StandardError; end
  
  # raised when attempting to interact with a profile that doesn't exist.
  class ProfileNotFound < StandardError; end
  
  # raised when attempting to log in with incorrect credentials.
  class AuthenticationException < StandardError; end
  
  # A reddit browsing session.
  class Session
    attr_reader :username, :cookie
    
    def self.login(username, password)
      session = Session.new(username, password)
      session.authenticate
      session
    end
    
    # initialize the session with a username and password.  Currently not used.
    def initialize(username = "", password = "")
      @username = username
      @password = password
      @logged_in = false
      @cookie = ''
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
    
    def owner
      User.new(@username)
    end
    
    def logged_in?
      @logged_in
    end
    
    def authenticate
      url = LOGIN_URL
      params = { 'reason' => '', 'op' => 'login-main', 'dest' => '/', 'user_login' => @username, 'passwd_login' => @password, 'rem' => '1' }
      result = Net::HTTP.post_form(URI.parse(url), params)
      resources = JSON.parse(result.body, :max_nesting => 0)
      if resources['error']
        raise AuthenticationException, resources['error']['message']
      else
        @logged_in = true
        @cookie = result.response['set-cookie']
      end
      pp resources
      return true
    end
    
    def get_article(url)
      url = INFO_URL.gsub('[url]', url)
      info = get(url)
      Article.new(info['data']['children'][0]['data'])
    end
    
    def like!(object)
      vote(object, 1)
    end
    
    def dislike!(object)
      vote(object, -1)
    end
    
    def save!(object)
      raise "Not Yet Implemented"
    end
    
    protected
    def vote(object, direction)
      params = { 'dir' => direction, 'id' => object.id, 'r' => 'reddit.com', 'uh' => '', 'vh' => '' }
      debugger
      info = post(VOTE_URL, params)
      pp info
      debugger
      info
    end
    
    def headers
      { 'Cookie' => self.cookie }
    end
    
    def get(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path + "?#{uri.query}", headers)
      JSON.parse(response.body, :max_nesting => 0)
    end
    
    def post(url, params = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      params_string = params.map { |k, v| "#{k}=#{v}" }.join('&')
      response = http.post(uri.path, params_string, headers)
      JSON.parse(response.body, :max_nesting => 0)
    end
  end
end
