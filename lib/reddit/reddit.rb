module Reddit
  
  # The main reddit or a subreddit.
  class Reddit < ResourceList
    attr_reader :name, :title, :url, :id, :description, :created_at
    
    # Initialize the reddit.  If no name is specified, the reddit will be the main reddit.
    def initialize(attributes = nil)
      if attributes.kind_of?(Hash)
        @name = attributes['name']
        @title = attributes['title']
        @subscribers = attributes['subscribers']
        @url = SUBREDDIT_URL.gsub('[subreddit]', @title)
        @id = attributes['id']
        @description = attributes['description']
        @created_at = Time.at(attributes['created']) unless attributes['created'].nil?
      else        
        @title = attributes
        @url = attributes.nil? ? BASE_URL : SUBREDDIT_URL.gsub('[subreddit]', @title)
      end
    end
    
    def subscriber_count
      @subscribers
    end
    
    def hot(options = {})
      articles 'hot', options
    end
    
    def top(options = {})
      articles 'top', options
    end
    
    def new(options = {})
      options[:querystring] = 'sort=new'
      articles 'new', options
    end
    
    def rising(options = {})
      options[:querystring] = 'sort=rising'
      articles 'new', options
    end
    
    def controversial(options = {})
      articles 'controversial', options
    end
    
    # Returns the articles found in this reddit.
    # Options are:
    #   Count: Return at least this many articles.
    #   Querystring: Querystring to append to resource request
    
    def articles(page = 'hot', options = {})
      get_resources("#{@url}#{page}", options) do |resource_json|
        Article.new(resource_json['data'])
      end
    end
  end
end