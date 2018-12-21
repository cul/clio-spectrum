class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    can :manage, ItemAlert if user.has_role?('item_alerts', 'manage')

    can :manage, BestBet if user.has_role?('best_bets', 'manage')
  end
end
