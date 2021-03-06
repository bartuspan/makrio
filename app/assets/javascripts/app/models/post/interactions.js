//require ../post

app.models.Post.Interactions = Backbone.Model.extend({
  url : function(){
    return this.post.url() + "/interactions"
  },

  initialize : function(options){
    this.post = options.post
    this.comments = new app.collections.Comments(this.get("comments"), {post : this.post})
    this.likes = new app.collections.Likes(this.get("likes"), {post : this.post});
    this.remixes = new app.collections.Remixes(this.get("remixes"), {post : this.post});
  },

  parse : function(resp){
    this.comments.reset(resp.comments)
    this.likes.reset(resp.likes)
    this.remixes.reset(resp.remixes)

    var comments = this.comments
      , likes = this.likes
      , remixes = this.remixes

    return {
      comments : comments,
      likes : likes,
      remixes : remixes,
      fetched : true
    }
  },

  likesCount : function(){
    return (this.get("fetched") ? this.likes.models.length : this.get("likes_count") )
  },

  remixCount : function(){
    return this.get("remix_count")
  },

  commentsCount : function(){
    return this.get("fetched") ? this.comments.models.length : this.get("comments_count")
  },

  userLike : function(){
    return this.likes.select(function(like){ return like.get("author").guid == app.currentUser.get("guid")})[0]
  },

  toggleLike : function(trackingOpts) {
    if(this.userLike()) {
      this.unlike(trackingOpts)
    } else {
      this.like(trackingOpts)
    }
  },

  like : function(trackingOpts) {
    var self = this;
    this.likes.create({}, {success : function(){
      self.trigger("change")
      self.set({"likes_count" : self.get("likes_count") + 1})
    }})

    app.instrument("track", "Like", trackingOpts)
  },

  unlike : function() {
    var self = this;
    this.userLike().destroy({success : function(model, resp) {
      self.trigger('change')
      self.set({"likes_count" : self.get("likes_count") - 1})
    }});

    app.instrument("track", "Unlike")
  },

  comment : function (text) {
    var self = this;

    this.comments.make(text).fail(function () {
      alert(Diaspora.I18n.t("failed_to_post_message"));
    }).done(function() {
      self.trigger('change') //updates after sync
    });

    this.trigger("change") //updates count in an eager manner

    app.instrument("track", "Comment")
  }
});