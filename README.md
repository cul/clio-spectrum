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
  
        ````brew install git````

2.  Get set up with git
  - Create an account on github.com if you don't already have one.
  - Configure your git user name and email.
        ````
        git config --global user.name "Your Name"
        git config --global user.email "your_email@whatever.com"
        ````
  - Install [github for mac](http://mac.github.com/) (optional) 


3.  Install [rvm](http://rvm.io/rvm/install)
        ````
        \curl -sSL https://get.rvm.io | bash -s stable --ruby
        ````
  
4. Install Qt webchain [more information](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit)
        ````
        brew install qt
        ````
  
5. Fork Fork the https://github.com/cul/clio-spectrum repo (fork button at top right of github web interface)

6. Clone the new forked repo onto your dev machine
        ````
        git clone https://github.com/yourusername/clio-spectrum
        ````

7. Install config files
