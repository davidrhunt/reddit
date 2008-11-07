require File.dirname(__FILE__) + '/spec_helper.rb'

describe Reddit::Session, "without logging in" do
  
  before(:each) do
    @reddit = Reddit::Session.new()
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
  
  def read_fixture(filename)
    fixture = File.dirname(__FILE__) + '/fixtures/' + filename
    File.read(fixture)
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
end
