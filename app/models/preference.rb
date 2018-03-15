class Preference < ApplicationRecord
  validates :login, uniqueness: true, presence: true
  validates :settings, presence: true






end
