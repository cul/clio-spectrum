class Ability
  include CanCan::Ability

  DATABASE_ADMINS = %w{jws2135}

  def initialize(user)
    user || User.new

    if DATABASE_ADMINS.include?(user.login)
      can :manage, DatabaseAlert
    end
  end
end
