require 'ipaddr'

class User < ActiveRecord::Base
  include Devise::Models::DatabaseAuthenticatable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :wind_authenticatable, :encryptable, authentication_keys: [:login]
  wind_host 'wind.columbia.edu'
  wind_service 'culscv'
  # Setup accessible (or protected) attributes for your model

  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :first_name, :last_name, :login

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

  def default_email
    login = send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
  end

  private

  def default_email
    login = send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
   end

  def generate_password
    self.password = SecureRandom.base64(8)
  end

  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new(host: 'ldap.columbia.edu', port: 389).search(base: 'o=Columbia University, c=US', filter: Net::LDAP::Filter.eq('uid', wind_login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          self.email = wind_login + '@columbia.edu'
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
