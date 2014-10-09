clio-spectrum
=============

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
  - Create an account on github.com if you don't already have one
  - Configure your git user name and email
  
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

4.   Change to the app directory 
````
    cd clio-spectrum
````

5.  Rename the config files
````
        mv config/solr.yml.SAMPLE config/solr.yml
        mv config/database.yml.SAMPLE config/database.yml
        mv config/app_config.yml.SAMPLE config/app_config.yml
````
  
6.  Start the server

````
        rails s
````
    
7.  Visit the running app at `localhost:3000`
