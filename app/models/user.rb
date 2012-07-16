class User < ActiveRecord::Base
  include Devise::Models::DatabaseAuthenticatable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :wind_authenticatable, :encryptable, :authentication_keys => [:login] 
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  # Setup accessible (or protected) attributes for your model

  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :first_name, :last_name, :login

  validates :login, :uniqueness => true, :presence => true
  
  def to_s
    email
  end
  
  def name
    [first_name, last_name].join(" ") 
  end
  def default_email
    login = self.send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
  end

end
