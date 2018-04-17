# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# title, url, description, keywords
BestBets.create( 
  title: 'Library Hours', 
  url: 'https://hours.library.columbia.edu/',
  description: '',
  keywords: '')
  
BestBets.create( 
  title: 'Butler Library Hours', 
  url: 'https://hours.library.columbia.edu/locations/butler-24',
  description: '',
  keywords: '')  