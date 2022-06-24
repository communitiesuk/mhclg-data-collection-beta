# **Developing locally on host machine**

The most common way to run a development version of the application is run with local dependencies.

Dependencies:

- Ruby
- Rails
- PostgreSQL
- NodeJS
- Gecko driver (https://github.com/mozilla/geckodriver/releases) [for running Selenium tests]

We recommend using RBenv to manage Ruby versions.

1. Install PostgreSQL

  Mac OS:
  ```bash
  brew install postgresql
  brew services start postgresql
  ```

  Linux (Debian):
  ```bash
  sudo apt install -y postgresql postgresql-contrib libpq-dev
  sudo systemctl start postgresql
  ```

2. Create a Postgres user
  ```bash
  sudo su - postgres -c "createuser <username> -P"
  ```

3. Install RBenv & Ruby-build

  Mac OS:
  ```bash
  brew install rbenv
  rbenv init
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  ```

  Linux (Debian):
  ```bash
  sudo apt install -y rbenv
  echo 'export PATH="/usr/local/rbenv/bin:\$PATH"' >> ~/.bashrc
  rbenv init
  echo "# Load RBenv" >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  ```

4. Install Ruby & Bundler

  ```bash
  rbenv install 3.1.2
  rbenv global 3.1.2
  gem install bundler
  ```

5. Install Javascript depenencies

  Mac OS:
  ```bash
  brew install node
  brew install yarn
  ```

  Linux (Debian):
  ```bash
  curl -sL https://deb.nodesource.com/setup_16.x | bash -
  sudo apt -y install nodejs
  mkdir "~/.npm-packages"
  npm config set prefix "~/.npm-packages"
  echo 'NPM_PACKAGES="~/.npm-packages"' >> ~/.bashrc
  echo 'export PATH="$PATH:$NPM_PACKAGES/bin"' >> ~/.bashrc
  npm install --global yarn
  ```

6. Clone the repo
  ```bash
  git clone git@github.com:communitiesuk/submit-social-housing-lettings-and-sales-data.git
  ```


## App setup (OS agnostic)

1. Copy the `.env.example` to `.env` and replace the database credentials with your local postgres user credentials.

2. Install the dependencies:\
  `bundle install && yarn install`

3. Create the database & run migrations:\
  `rake db:create db:migrate`

4. Seed the database if required:\
  `rake db:seed`

5. Start the dev servers

  a. Using foreman:\
  `./bin/dev`

  b. Individually:\

    i. Rails:\
    `bundle exec rails s`

    ii. JS (for hot reloading):\
    `yarn build --mode=development --watch`

  If you're not modifying front end assets you can bundle them as a one off task:\
    `yarn build --mode=development`

Development mode will target the latest versions of Chrome, Firefox and Safari for transpilation while production mode will target older browsers.

The Rails server will start on <http://localhost:3000>.

Running the test suite (front end assets need to be built or server needs to be running):\
  `bundle exec rspec`


# **Using Docker**


1. Build the image:\
`docker-compose build`

2. Run the database migrations:\
`docker-compose run --rm app /bin/bash -c 'rake db:migrate'`

3. Seed the database if required:\
`docker-compose run --rm app /bin/bash -c 'rake db:seed'`

4. To be able to debug with Pry run the app using:\
`docker-compose run --service-ports app`

If this is not needed you can run `docker-compose up` as normal

The Rails server will start on <http://localhost:8080>.
