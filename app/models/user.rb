require 'ipaddr'
require 'resolv'

class User < ActiveRecord::Base
  include Devise::Models::DatabaseAuthenticatable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  if APP_CONFIG['web_authentication'] == 'wind'
    devise :wind_authenticatable, :encryptable, authentication_keys: [:login]
    # CUIT Broke Wind, 2015-02-09
    # wind_host 'wind.columbia.edu'
    # wind_service 'culscv'
    # Allow us to adjust more quickly to the shifting sands of central support...
    wind_host APP_CONFIG['wind_host']
    wind_service APP_CONFIG['wind_service']
  end

  if APP_CONFIG['web_authentication'] == 'cas'
    # CAS is ready.  No more wind.
    # devise :cas_authenticatable, :encryptable, authentication_keys: [:login]
    devise :cas_authenticatable, authentication_keys: [:login]
  end


  # Rails 4 - don't do this.  Will our gems do it for us?
  # # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :first_name, :last_name, :login

  validates :login, uniqueness: true, presence: true

  before_validation(:default_email, on: :create)
  before_validation(:generate_password, on: :create)
  before_create :set_personal_info_via_ldap

  def self.on_campus?(ip_addr)
    # check passed string against regexp from standard library
    return false unless ip_addr =~ Resolv::IPv4::Regex

    APP_CONFIG['COLUMBIA_IP_RANGES'].any? do |ir|
      IPAddr.new(ir) === ip_addr
    end
  end

  def has_role?(area, role, admin_okay = true)
    login.in?(PERMISSIONS_CONFIG[area][role]) ||
      (admin_okay && login.in?(PERMISSIONS_CONFIG['site']['manage']))
  end

  def to_s
    email
  end

  def name
    [first_name, last_name].join(' ')
  end

  # This method is private, below.
  # def default_email
  #   raise
  #   login = send User.wind_login_field
  #   mail = "#{login}@columbia.edu"
  #   self.email = mail
  # end

  private

  def default_email
    # raise
    # login = send User.wind_login_field
    login = self.login
    mail = "#{login}@columbia.edu"
    self.email = mail
   end

  def generate_password
    self.password = SecureRandom.base64(8)
  end

  def set_personal_info_via_ldap
    # raise
    # if wind_login
    if login
      # entry = Net::LDAP.new(host: 'ldap.columbia.edu', port: 389).search(base: 'o=Columbia University, c=US', filter: Net::LDAP::Filter.eq('uid', wind_login)) || []
      entry = Net::LDAP.new(host: 'ldap.columbia.edu', port: 389).search(base: 'o=Columbia University, c=US', filter: Net::LDAP::Filter.eq('uid', login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          # self.email = wind_login + '@columbia.edu'
          self.email = login + '@columbia.edu'
        end
        if User.column_names.include? 'last_name'
          self.last_name = entry[:sn].to_s.gsub('[', '').gsub(']', '').gsub(/\"/, '')
        end
        if User.column_names.include? 'first_name'
          self.first_name = entry[:givenname].to_s.gsub('[', '').gsub(']', '').gsub(/\"/, '')
        end
      end
    end

    self
  end
end
