require 'hpricot'

module Reddit
  BASE_URL = "http://www.reddit.com/"
  PROFILE_URL = BASE_URL + "user/[username]/"
  SUBREDDIT_URL = BASE_URL + "r/[subreddit]/"
  COMMENTS_URL = BASE_URL + "comments/[id]/"
  
  LOGIN_URL = BASE_URL + "api/login.json"
  INFO_URL = BASE_URL + "api/info.json?count=1&url=[url]"
  BY_ID_URL = BASE_URL + "by_id/[name].json"
  VOTE_URL = BASE_URL + "api/vote.json"
  HIDE_URL = BASE_URL + "api/hide.json"
  UNHIDE_URL = BASE_URL + "api/unhide.json"
  SAVE_URL = BASE_URL + "api/save.json"
  UNSAVE_URL = BASE_URL + "api/unsave.json"
  SUBSCRIBE_URL = BASE_URL + "api/subscribe.json"
  
  SUBSCRIBER_URL = BASE_URL + "reddits/mine/subscriber.json"
  CONTRIBUTOR_URL = BASE_URL + "reddits/mine/contributor.json"
  MODERATOR_URL = BASE_URL + "reddits/mine/moderator.json"
  
  # raised when attempting to interact with a subreddit that doesn't exist.
  class SubredditNotFound < StandardError; end
  
  # raised when attempting to interact with a profile that doesn't exist.
  class ProfileNotFound < StandardError; end
  
  # raised when attempting to log in with incorrect credentials.
  class AuthenticationException < StandardError; end
  
  # raised when the modhash (uh/userhash) cannot be found within the page body after authentication.
  class ModhashNotFound < StandardError; end
  
  # raised when the requested action requires the user to be logged in.
  class MustBeLoggedIn < StandardError; end
  
  # A reddit browsing session.
  class Session
    attr_reader :username, :cookie, :modhash
    
    def self.login(username, password)
      Session.new(username, password) do |session|
        session.authenticate
        session.fetch_modhash
      end
    end
    
    # initialize the session with a username and password.  Currently not used.
    def initialize(username = "", password = "")
      @username = username
      @password = password
      @logged_in = false
      @cookie = ''
      yield self if block_given?
    end
    
    # return the main reddit.
    def main
      return Reddit.new
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
      require_login
      User.new(@username)
    end
    
    def logged_in?
      @logged_in
    end
    
    def authenticate
      url = LOGIN_URL
      params = { 'rem' => 'on', 'user' => @username, 'passwd' => @password, 'op' => 'login-main', 'id' => '%23login_login-main' }
      pp params
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
    
    # The 'modhash' is a special token that is passed around to various Reddit API calls. It currently must be extracted
    # from the page body once you have successfully authenticated with Reddit. To extract the modhash, we fetch the main
    # Reddit home page and then rip through the script tags with Hpricot.
    def fetch_modhash
      require_login
      data = get(BASE_URL)
      doc = Hpricot(data)
      jscript = doc.at('script').innerHTML
      match = jscript.match(/modhash: \'([a-z0-9]+?)\',/)
      raise ModhashNotFound, "Unable to find the modhash in the page source" unless match
      @modhash = match[1]
    end
    
    def subscribing
      load_subreddits_from(SUBSCRIBER_URL)
    end
    
    def contributing
      load_subreddits_from(CONTRIBUTOR_URL)
    end
    
    def moderating
      load_subreddits_from(MODERATOR_URL)
    end
    
    def get_article(url)
      url = INFO_URL.gsub('[url]', url)
      info = get_json(url)
      Article.new(info['data']['children'][0]['data'])
    end
    
    def like!(object)
      vote(object, 1)
      object.likes = true
      object.score += 1
      object.ups += 1
    end
    
    def dislike!(object)
      vote(object, -1)
      object.likes = false
      object.score += 1
      object.downs += 1
    end
    
    def clear!(object)
      vote(object, 0)
      object.likes = nil
      object.score -= 1
    end
    
    def save!(object)
      require_login
      params = { 'id' => object.name, 'uh' => self.modhash }
      post_json(SAVE_URL, params)
      object.saved = true
    end
    
    def unsave!(object)
      require_login
      params = { 'id' => object.name, 'uh' => self.modhash }
      post_json(UNSAVE_URL, params)
      object.saved = false
    end
    
    def hide!(object)
      require_login
      params = { 'id' => object.name, 'uh' => self.modhash }
      post_json(HIDE_URL, params)
      object.hidden = true
    end
    
    def show!(object)
      require_login
      params = { 'id' => object.name, 'uh' => self.modhash }
      post_json(UNHIDE_URL, params)
      object.hidden = false
    end
    
    def subscribe!(subreddit)
      require_login
      params = { 'sr' => subreddit.name, 'action' => 'sub', 'uh' => self.modhash }
      post_json(SUBSCRIBE_URL, params)
    end
    
    def unsubscribe!(subreddit)
      require_login
      params = { 'sr' => subreddit.name, 'action' => 'unsub', 'uh' => self.modhash }
      post_json(SUBSCRIBE_URL, params)
    end
    
    protected
    def vote(object, direction)
      require_login
      params = { 'dir' => direction, 'id' => object.name, 'r' => 'reddit.com', 'uh' => self.modhash, 'vh' => '' }
      post_json(VOTE_URL, params)
    end
    
    def headers
      { 'Cookie' => self.cookie }
    end
    
    def get(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path + "?#{uri.query}", headers)
      response.body
    end
    
    def get_json(url)
      JSON.parse(get(url), :max_nesting => 0)
    end
    
    def post(url, params = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      params_string = params.map { |k, v| "#{k}=#{v}" }.join('&')
      response = http.post(uri.path, params_string, headers)
      response.body
    end
    
    def post_json(url, params = {})
      JSON.parse(post(url, params), :max_nesting => 0)
    end
    
    def load_subreddits_from(url)
      require_login
      json = get_json(url)
      pp json
      json['data']['children'].map { |data| Reddit.new(data['data']) }
    end
    
    def require_login
      raise MustBeLoggedIn, "You must be logged in." unless logged_in?
    end
  end
end
