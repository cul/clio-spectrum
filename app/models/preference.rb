class Preference < ActiveRecord::Base
  validates :login, uniqueness: true, presence: true
  validates :settings, presence: true






end
