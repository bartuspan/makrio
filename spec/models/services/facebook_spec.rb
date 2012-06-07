require 'spec_helper'

describe Services::Facebook do
  before do
    @user = alice
    @post = @user.post(:status_message, :text => "hello", :to =>@user.aspects.first.id, :public =>true)
    @service = Services::Facebook.new(:access_token => "yeah")
    @user.services << @service

    @old_namespace = AppConfig[:open_graph_namespace]
    AppConfig[:open_graph_namespace] = 'makr_app'
  end

  after do
    AppConfig[:open_graph_namespace] = @old_namespace
  end

  describe '#post' do
    it 'posts a status message to facebook' do
      stub_request(:post, "https://graph.facebook.com/me/#{AppConfig[:open_graph_namespace]}:make").
          to_return(:status => 200, :body => "", :headers => {})
      @service.post(@post)
    end

    it 'swallows exception raised by facebook always being down' do
      pending "temporarily disabled to figure out while some requests are failing"
      
      stub_request(:post,"https://graph.facebook.com/me/#{AppConfig[:open_graph_namespace]}:make").
        to_raise(StandardError)
      @service.post(@post)
    end

    it 'should call public message' do
      stub_request(:post, "https://graph.facebook.com/me/#{AppConfig[:open_graph_namespace]}:make").
        to_return(:status => 200)
      url = "foo"
      @service.should_not_receive(:public_message)
      @service.post(@post, url)
    end
  end

  describe "#open_graph_post" do
    it "posts the supplied action to facebook's open graph" do
      stub_request(:post, "https://graph.facebook.com/me/#{AppConfig[:open_graph_namespace]}:love").
          to_return(:status => 200, :body => "", :headers => {})
      @service.open_graph_post("love", @post)
    end
  end

  describe "#profile_photo_url" do
    it 'returns a large profile photo url' do
      @service.uid = "abc123"
      @service.access_token = "token123"
      @service.profile_photo_url.should == 
      "https://graph.facebook.com/abc123/picture?type=large&access_token=token123"
    end
  end
end
