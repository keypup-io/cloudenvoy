# Example usage with Rails

## Run using the local gcloud Pub/Sub emulator

1. Install dependencies: `bundle install`
2. Intall the Pub/Sub emulator: `gcloud components install pubsub-emulator && gcloud components update`
3. Run the Pub/Sub emulator: `gcloud beta emulators pubsub start`
4. Launch the server: `foreman start`
5. Open a Rails console: `./bin/console`
6. Create the topics and subscriptions (one time setup - no need to redo it until you restart the pubsub emulator)
```ruby
Cloudenvoy.setup_publishers
Cloudenvoy.setup_subscribers
```
7. Publish messages:
```ruby
HelloPublisher.publish('Some message')
```
8. Tail the logs to see how message get processed by `HelloSubscriber`
9. Try sending multiple messages at once:
```ruby
HelloPublisher.publish_all(['message1', 'message2', 'message3'])
```

## Run using GCP Pub/Sub

1. Ensure that your [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts) is setup.
2. Install dependencies: `bundle install`
3. Start an [ngrok](https://ngrok.com) tunnel: `ngrok http 3000`
4. Edit the [initializer](./config/initializers/cloudenvoy.rb) 
    * Add the configuration of your GCP Pub/Sub
    * Set `config.processor_host` to the ngrok http or https url
    * Set `config.mode` to `:production`
5. Launch the server: `foreman start`
6. Open a Rails console: `./bin/console`
7. Create the topics and subscriptions (one time setup)
```ruby
Cloudenvoy.setup_publishers
Cloudenvoy.setup_subscribers
```
8. Publish messages
```ruby
HelloPublisher.publish('Some message')
```
9. Tail the logs to see how message get processed by `HelloSubscriber`