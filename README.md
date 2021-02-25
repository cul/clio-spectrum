# clio-spectrum


Columbia Libraries Unified Search &amp; Discovery

**Getting started on OSX**

1. Install tools
  - install XCode from app store and Xcode command line tools

  - install [mysql]( http://dev.mysql.com/downloads/mysql/ )

  - install [homebrew](http://brew.sh/)
  
        ````
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        ````
  - install git
  
        ````
        brew install git
        ````
  - install [rvm](http://rvm.io/rvm/install)

        ````
        \curl -sSL https://get.rvm.io | bash -s stable --ruby
        ````
  
  - install Qt webkit [more information](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit)

        ````
        brew install qt
        ````


2.  Get set up with git
  - create an account on github.com if you don't already have one
  - configure your git user name and email
  
        ````
        git config --global user.name "Your Name"
        git config --global user.email "your_email@whatever.com"
        ````

  - Install [github for mac](http://mac.github.com/) (optional, but has some very nice features) 



3. [Fork and clone](https://help.github.com/articles/fork-a-repo/) the repo
  - fork the https://github.com/cul/clio-spectrum repo (fork button at top right of github web interface)
  - clone the new forked repo onto your dev machine
 
        ````
        git clone https://github.com/yourusername/clio-spectrum
        ````
 
4. Prepare your local environment
 - change to the app directory`cd clio-spectrum`

 - check out the develop branch `git checkout develop`

 - run `bundle` to install the gems 
        
 - run the database migrations `rake db:migrate`

 - rename the config files
        ````
        mv config/blacklight.yml.SAMPLE config/blacklight.yml
        mv config/database.yml.SAMPLE config/database.yml
        mv config/app_config.yml.SAMPLE config/app_config.yml
        ````
 - load the Locations, Libraries and Library Hours 
 
        ````
        rake hours:update_all
        rake locations:load
        ````
6. Start the server `rails s`

7. Visit the running app in your browser at `localhost:3000`

8. Run the test suite
  - prepare your test database
  
        ````
        rake db:test:prepare
        rake hours:sync RAILS_ENV=test
        rake locations:load RAILS_ENV=test
        ````
  - run `rspec` and ensure that all tests are passing (green)


**Contributing to CLIO**

Contributions can be submitted to CLIO by making a [pull request](https://help.github.com/articles/using-pull-requests/), following GitHub's [fork-and-pull](https://help.github.com/articles/using-pull-requests/#fork--pull) model.  [Pull requests](https://help.github.com/articles/using-pull-requests/) should be submitted from feature (topic) branches and be [based on](https://help.github.com/articles/using-pull-requests/#changing-the-branch-range-and-destination-repository) CLIO's **develop** (not master) branch.

[Read more about the GitHub workflow](https://guides.github.com/introduction/flow/index.html).  

1. Create a feature branch off the develop branch

  ````
  git fetch origin
  git checkout origin/develop
  git checkout -b your-new-branch
  ````
2. Make and commit your changes

3. Assure that the test suite is all green

4. Submit a pull request to the develop branch
