require File.dirname(__FILE__) + '/spec_helper.rb'

module SessionHelpers
  def fails_login_requirement
    lambda { yield }.should raise_error(Reddit::MustBeLoggedIn)
  end
  
  def meets_login_requirement
    lambda { yield }.should_not raise_error(Reddit::MustBeLoggedIn)
  end
end

describe Reddit::Session, "without logging in" do
  include SessionHelpers
  
  before(:each) do
    @reddit = Reddit::Session.new()
    @article = Reddit::Article.new({})
  end

  it "should grab the main page" do
    @reddit.main.should_not be_nil
  end
  
  it "should grab a user's profile page" do
    @reddit.user("radhruin").should_not be_nil
  end
  
  it "should grab a subreddit" do
    @reddit.subreddit("programming").should_not be_nil
  end
  
  it "should not be logged in" do
    @reddit.should_not be_logged_in
  end
  
  it "should not allow you to return an owner" do 
    fails_login_requirement { @reddit.owner }
  end
  
  it "should not allow you to like something" do 
    fails_login_requirement { @reddit.like!(@article) }
  end
  
  it "should not allow you to dislike something" do 
    fails_login_requirement { @reddit.dislike!(@article) }
  end
  
  it "should not allow you to clear the rating on something" do 
    fails_login_requirement { @reddit.clear!(@article) }
  end
  
  it "should not allow you to save something" do 
    fails_login_requirement { @reddit.save!(@article) }
  end
  
  it "should not allow you to unsave something" do 
    fails_login_requirement { @reddit.unsave!(@article) }
  end
  
  it "should not allow you to hide something" do 
    fails_login_requirement { @reddit.hide!(@article) }
  end
  
  it "should not allow you to show something" do 
    fails_login_requirement { @reddit.show!(@article) }
  end
  
  it "should not allow you to subscribe to something" do 
    fails_login_requirement { @reddit.subscribe!(@article) }
  end
  
  it "should not allow you to unsubscribe from something" do 
    fails_login_requirement { @reddit.unsubscribe!(@article) }
  end
end

describe Reddit::Session, "when logged in" do
  include SessionHelpers
  
  before(:each) do
    @reddit = Reddit::Session.new()
    @reddit.stub!(:logged_in?).and_return(true)
    @reddit.stub!(:username).and_return('blakewatters')
    @reddit.stub!(:cookie).and_return('monster')
    @reddit.stub!(:modhash).and_return('jxg28km2j1jdjgsa27931')
  end
  
  it "should load subscribed subreddits" do
    @reddit.should_receive(:load_subreddits_from).with(Reddit::SUBSCRIBER_URL)
    @reddit.subscribing
  end
  
  it "should load contributor subreddits" do
    @reddit.should_receive(:load_subreddits_from).with(Reddit::CONTRIBUTOR_URL)
    @reddit.contributing
  end
  
  it "should load moderator subreddits" do
    @reddit.should_receive(:load_subreddits_from).with(Reddit::MODERATOR_URL)
    @reddit.moderating
  end
  
  describe ".subscribing" do
    before(:each) do
      json_payload = read_fixture('subscriber.json')
      @reddit.should_receive(:get).with(Reddit::SUBSCRIBER_URL).and_return(json_payload)
      @subreddits = @reddit.subscribing
    end
    
    it "should load subscriber sub-reddits" do      
      @subreddits.should_not be_nil
    end
    
    it { @subreddits.should be_kind_of(Array) }
    
    it "should load 45 subreddits" do
      @subreddits.size.should == 45
    end
    
    describe "should load the science subreddit first" do
      before(:each) do
        @science_subreddit = @subreddits.first
      end
      
      it { @science_subreddit.title.should == 'science' }
      it { @science_subreddit.name.should == 't5_mouw' }
      it { @science_subreddit.subscriber_count.should == 76512 }
      it { @science_subreddit.description.should == '' }
      it { @science_subreddit.created_at.should == Time.parse("Wed Oct 18 09:54:26 -0400 2006") }
    end
  end
  
  it "should allow you to retrieve the account owner" do 
    meets_login_requirement { @reddit.owner }
  end
  
  it "should allow you to like something" do 
    meets_login_requirement { @reddit.like!(@article) }
  end

  it "should allow you to dislike something" do 
    meets_login_requirement { @reddit.dislike!(@article) }
  end

  it "should allow you to clear the rating on something" do 
    meets_login_requirement { @reddit.clear!(@article) }
  end

  it "should allow you to save something" do 
    meets_login_requirement { @reddit.save!(@article) }
  end

  it "should allow you to unsave something" do 
    meets_login_requirement { @reddit.unsave!(@article) }
  end

  it "should allow you to hide something" do 
    meets_login_requirement { @reddit.hide!(@article) }
  end

  it "should allow you to show something" do 
    meets_login_requirement { @reddit.show!(@article) }
  end

  it "should allow you to subscribe to something" do 
    meets_login_requirement { @reddit.subscribe!(@article) }
  end

  it "should allow you to unsubscribe from something" do 
    meets_login_requirement { @reddit.unsubscribe!(@article) }
  end
end
