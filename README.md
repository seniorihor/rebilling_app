# Rebilling App

## Setup Project

Follow these steps to set up the Rebilling App project on your local machine:

### Steps (with docker)

1. **Build docker image:**
  ```sh
    docker build -t rebilling_app .
  ```

2. **Run container:**
  ```sh
    # rails server will run automatically
    docker run -p 3000:3000 --name rebilling_app rebilling_app
  ```

3. **Connect to container:**
  ```sh
    docker exec -it rebilling_app sh
  ```

### Steps (without docker)

1. **Install dependencies:**
  ```sh
  bundle install
  ```

2. **Set up the database:**
  ```sh
  bundle exec rails db:create
  bundle exec rails db:migrate
  ```

3. **Start the Rails server:**
  ```sh
    bundle exec rails server
  ```

### Running Tests

To run the test suite, execute:
```sh
  bundle exec rspec
```

## Simulate Rebilling

You need to have the rails server running on port 3000.
To simulate the rebilling process, run the seeds creation with the following command:
```sh
  bundle exec rails db:seed
```

\* To see how it works with old (active/inactive) subscriptions, you can run it several times
