class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
  end
end
