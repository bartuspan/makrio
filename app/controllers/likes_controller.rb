#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require Rails.root.join("app", "presenters", "post_presenter")

class LikesController < ApplicationController
  include ApplicationHelper
  before_filter :authenticate_user!

  respond_to :html,
             :mobile,
             :json

  def create
    @like = current_user.like!(target) if target rescue ActiveRecord::RecordInvalid

    if @like
      respond_to do |format|
        format.html { render :nothing => true, :status => 201 }
        format.mobile { redirect_to post_path(@like.post_id) }
        format.json { render :json => LikePresenter.new(@like, current_user), :status => 201 }
      end
    else
      render :nothing => true, :status => 422
    end
  end

  def destroy
    @like = Like.find_by_id_and_author_id!(params[:id], current_user.person.id)

    @like.destroy
    respond_to do |format|
      format.json { render :nothing => true, :status => 204 }
    end
  end

  #I can go when the old stream goes.
  def index
    @likes = target.likes.includes(:author => :profile)
    @people = @likes.map(&:author)

    respond_to do |format|
      format.all { render :layout => false }
      format.json { render :json => LikePresenter.as_collection(@likes, current_user) }
    end
  end

  protected

  def target
    @target ||= if params[:post_id]
      Post.find_by_guid_or_id_with_user(params[:post_id], current_user)
    else
      Comment.find(params[:comment_id]).tap do |comment|
       raise(ActiveRecord::RecordNotFound.new) unless current_user.find_visible_shareable_by_id(Post, comment.commentable_id)
      end
    end
  end
end
