# Example usage with Rails

## Run using the local gcloud Pub/Sub emulator

1. Install dependencies: `bundle install`
2. Launch the server: `foreman start`
3. Open a Rails console: `rails c`
4. Publish messages:
```ruby
DummyPublisher.publish({ foo: 'bar' })
```

## Run using GCP Pub/Sub

1. Ensure that your [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts) is setup.
2. Install dependencies: `bundle install`
3. Start an [ngrok](https://ngrok.com) tunnel: `ngrok http 3000`
4. Edit the [initializer](./config/initializers/cloudenvoy.rb) 
    * Add the configuration of your GCP Pub/Sub
    * Set `config.processor_host` to the ngrok http or https url
    * Set `config.mode` to `:production`
5. Launch the server: `foreman start web`
6. Open a Rails console: `rails c`
7. Publish messages
```ruby
DummyWorker.perform_async
```
