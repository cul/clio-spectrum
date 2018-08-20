class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.has_role?('item_alerts', 'manage')
      can :manage, ItemAlert
    end

    can :manage, BestBet if user.has_role?('best_bets', 'manage')

  end
end
