class UserPresenter
  def initialize(user, current_user=nil)
    @user = user
    @person = @user.person
    @current_user = current_user
  end

  def as_json(opts={})
    @user.person.as_api_response(:backbone).update(
      {
        admin: @user.admin?,
        services: self.services,
        username: @user.username,
        configured_services: self.configured_services,
        notifications_count: self.notifications_count,
        :followers => @person.followers_count,
        :following =>@person.followed_count, 
        getting_started: @user.getting_started
      }
    )
  end

  def services
    @services ||= ServicePresenter.as_collection(@user.services, @current_user)
  end

  def configured_services
    @configured_services ||= @user.services.map(&:provider)
  end

  def notifications_count
    @notification_count ||= @user.unread_notifications.count
  end
end
