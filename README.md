# Rebilling App

## Setup Project

Follow these steps to set up the Rebilling App project on your local machine:

### Steps

1. **Install dependencies:**
  ```sh
  bundle install
  ```

2. **Set up the database:**
  ```sh
  rails db:create
  rails db:migrate
  rails db:seed
  ```

3. **Start the Rails server:**
  ```sh
  rails server
  ```


### Running Tests

To run the test suite, execute:
```sh
rspec
```

## Symulate Rebilling

To symulate the rebilling process, you can use seeds creation with the following command:
```sh
rails db:seed
```

\* To see how it works with old (active/inavtive) subscriptions, you can run it twice