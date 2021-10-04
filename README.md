![Build Status](https://github.com/keypup-io/cloudenvoy/workflows/Test/badge.svg) [![Gem Version](https://badge.fury.io/rb/cloudenvoy.svg)](https://badge.fury.io/rb/cloudenvoy)

# Cloudenvoy

Cross-application messaging framework for GCP Pub/Sub.

Cloudenvoy provides an easy to use interface to GCP Pub/Sub. Using Cloudenvoy you can simplify cross-application event messaging by using a publish/subscribe approach. Pub/Sub is particularly suited for micro-service architectures where a great number of components need to be aware of other components' activities. In these architectures using point to point communication via API can quickly become messy and hard to maintain due to the number of interconnections to maintain.

Pub/Sub solves that event distribution problem by allowing developers to define topics, publishers and subscribers to distribute and process event messages. Cloudenvoy furthers simplifies the process of setting up Pub/Sub by giving developers an object-oriented way of managing publishers and subscribers.

Cloudenvoy works with the local pub/sub emulator as well, meaning that you can work offline without access to GCP.

**Maturity**: The gem is relatively young but is production-friendly. We at Keypup have already processed hundreds of thousands of pub/sub messages through Cloudenvoy. If you spot any bug, feel free to report it! we're aiming at a `v1.0.0` around Q1 2022.

## Summary

1. [Installation](#installation)
2. [Get started with Rails](#get-started-with-rails)
3. [Configuring Cloudenvoy](#configuring-cloudenvoy)
    1. [Pub/Sub authentication & permissions](#pubsub-authentication--permissions)
    2. [Cloudenvoy initializer](#cloudenvoy-initializer)
4. [Creating topics and subscriptions](#creating-topics-and-subscriptions)
    1. [Sending messages](#sending-messages)
    2. [Publisher implementation layout](#publisher-implementation-layout)
5. [Receiving messages](#receiving-messages)
6. [Error Handling](#error-handling)
7. [Testing](#testing)
    1. [Test helper setup](#test-helper-setup)
    2. [In-memory queues](#in-memory-queues)
    3. [Unit tests](#unit-tests)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloudenvoy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cloudenvoy

## Get started with Rails

Cloudenvoy is pre-integrated with Rails. Follow the steps below to get started.

Install the pub/sub local emulator
```bash
gcloud components install pubsub-emulator
gcloud components update
```

Add the following initializer
```ruby
# config/initializers/cloudenvoy.rb

Cloudenvoy.configure do |config|
  #
  # GCP Configuration
  #
  config.gcp_project_id = 'some-project'
  config.gcp_sub_prefix = 'my-app'

  #
  # Adapt the server port to be the one used by your Rails web process
  #
  config.processor_host = 'http://localhost:3000'

  #
  # If you do not have any Rails secret_key_base defined, uncomment the following
  # This secret is used to authenticate messages sent to the processing endpoint
  # of your application.
  #
  # config.secret = 'some-long-token'
end
```

Define a publisher or use generator: `rails generate cloudenvoy:publisher Dummy`
```ruby
# app/publishers/dummy_publisher.rb

class DummyPublisher
  include Cloudenvoy::Publisher

  cloudenvoy_options topic: 'test-msgs'

  # Format the message payload. The payload can be a hash
  # or a string.
  def payload(msg)
    {
      type: 'message',
      content: msg
    }
  end
end
```

Define a subscriber or use generator: `rails generate cloudenvoy:subscriber Dummy`
```ruby
# app/subscribers/dummy_subscriber.rb

class HelloSubscriber
  include Cloudenvoy::Subscriber

  cloudenvoy_options topics: ['test-msgs']

  # Do something with the message
  def process(message)
    logger.info("Received message #{message.payload.dig('content')}")
  end
end
```

Launch the pub/sub emulator:
```bash
gcloud beta emulators pubsub start
```

Use cloudenvoy to setup your topic and subscription
```bash
bundle exec rake cloudenvoy:setup
```

Launch Rails
```bash
rails s -p 3000
```

Open a Rails console and send a message
```ruby
  DummyPublisher.publish('Hello pub/sub')
```

Your Rails logs should display the following:
```log
Started POST "/cloudenvoy/receive?token=1234" for 66.102.6.140 at 2020-09-16 11:12:47 +0200
Processing by Cloudenvoy::SubscriberController#receive as JSON
  Parameters: {"message"=>{"attributes"=>{"kind"=>"hello"}, "data"=>"eyJ0eXBlIjoibWVzc2FnZSIsImNvbnRlbnQiOiJIZWxsbyBmcmllbmQifQ==", "messageId"=>"1501653492745522", "message_id"=>"1501653492745522", "publishTime"=>"2020-09-16T09:12:45.214Z", "publish_time"=>"2020-09-16T09:12:45.214Z"}, "subscription"=>"projects/keypup-dev/subscriptions/my-app.hello_subscriber.test-msgs", "token"=>"eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDAyNDc0OTh9.5SbVsDCZLcyoFXseCpPuvE7KY7WXqIQtO6ceoFXcrdw", "subscriber"=>{"message"=>{"attributes"=>{"kind"=>"hello"}, "data"=>"eyJ0eXBlIjoibWVzc2FnZSIsImNvbnRlbnQiOiJIZWxsbyBmcmllbmQifQ==", "messageId"=>"1501653492745522", "message_id"=>"1501653492745522", "publishTime"=>"2020-09-16T09:12:45.214Z", "publish_time"=>"2020-09-16T09:12:45.214Z"}, "subscription"=>"projects/keypup-dev/subscriptions/my-app.hello_subscriber.test-msgs"}}
[Cloudenvoy][HelloSubscriber][1501653492745522] Processing message... -- {:id=>"1501653492745522", :metadata=>{}, :topic=>"test-msgs"}
[Cloudenvoy][HelloSubscriber][1501653492745522] Received message Hello pub/sub -- {:id=>"1501653492745522", :metadata=>{}, :topic=>"test-msgs"}
[Cloudenvoy][HelloSubscriber][1501653492745522] Processing done after 0.001s -- {:id=>"1501653492745522", :metadata=>{}, :topic=>"test-msgs", :duration=>0.001}
Completed 204 No Content in 1ms (ActiveRecord: 0.0ms | Allocations: 500)
```

Hurray! Your published message was immediately processed by the subscriber.

## Configuring Cloudenvoy

### Pub/Sub authentication & permissions

The Google Cloud library authenticates via the Google Cloud SDK by default. If you do not have it setup then we recommend you [install it](https://cloud.google.com/sdk/docs/quickstarts).

Other options are available such as using a service account. You can see all authentication options in the [Google Cloud Authentication guide](https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-bigquery/AUTHENTICATION.md).

In order to function properly Cloudenvoy requires the authenticated account to have the following IAM permissions:
- `pubsub.subscriptions.create`
- `pubsub.subscriptions.get`
- `pubsub.topics.create`
- `pubsub.topics.get`
- `pubsub.topics.publish`

To get started quickly you can add the `roles/pubsub.admin` role to your account via the [IAM Console](https://console.cloud.google.com/iam-admin/iam). This is not required if your account is a project admin account.

### Cloudenvoy initializer

The gem can be configured through an initializer. See below all the available configuration options.

```ruby
# config/initializers/cloudenvoy.rb

Cloudenvoy.configure do |config|
  #
  # If you do not have any Rails secret_key_base defined, uncomment the following.
  # This secret is used to authenticate messages sent to the processing endpoint
  # of your application.
  #
  # Default with Rails: Rails.application.credentials.secret_key_base
  #
  # config.secret = 'some-long-token'

  #
  # GCP Configuration
  #
  config.gcp_project_id = 'some-project'

  #
  # Specify the namespace for your subscriptions
  #
  # The gem attempts to keep GCP subscriptions organized by
  # properly namespacing them. Each subscription has the following
  # format:
  # > projects/<gcp_project_id>/subscriptions/<gcp_sub_prefix>.<subscriber_class>.<topic>
  #
  config.gcp_sub_prefix = 'my-app'

  #
  # Specify the publicly accessible host for your application
  #
  # > E.g. in development, using the pub/sub local emulator
  # config.processor_host = 'http://localhost:3000'
  #
  # > E.g. in development, using `config.mode = :production` and ngrok
  # config.processor_host = 'https://111111.ngrok.io'
  #
  config.processor_host = 'https://app.mydomain.com'

  #
  # Specify the mode of operation:
  # - :development => messages will be pushed to the local pub/sub emulator
  # - :production => messages will be pushed to Google Cloud Pub/Sub. Requires a publicly accessible domain.
  #
  # Defaults to :development unless CLOUDENVOY_ENV or RAILS_ENV or RACK_ENV is set to something else.
  #
  # config.mode = Rails.env.production? || Rails.env.my_other_env? ? :production : :development

  #
  # Specify the logger to use
  #
  # Default with Rails: Rails.logger
  # Default without Rails: Logger.new(STDOUT)
  #
  # config.logger = MyLogger.new(STDOUT)
end
```

### Creating topics and subscriptions

Topics and subscriptions can be created using the provided Rake tasks:
```bash
# Setup publishers (topics) and subscribers (subscriptions) in one go
bundle exec rake cloudenvoy:setup

# Or set them up individually
bundle exec rake cloudenvoy:setup_publishers
bundle exec rake cloudenvoy:setup_subscribers
```

For non-rails applications you can run the following in a console to setup your publishers and subscribers:
```ruby
DummyPublisher.setup
DummySubscriber.setup
```

## Publishing messages

### Sending messages

Cloudenvoy provides a helper method to publish arbitrary messages to any topic.
```ruby
Cloudenvoy.publish('my-topic', { 'some' => 'payload' }, { 'optional' => 'message attribute' })
```

This helper is useful for sending basic messages however it is not the preferred way of sending messages as you will quickly clutter your application with message formatting logic over time.

Cloudenvoy provides an object-oriented way of sending messages allowing developers to separate their core business logic from any kind of message formatting logic. These are called `Publishers`.

The example below shows you how to publish new users to a topic using Cloudenvoy publishers:
```ruby
# app/publishers/user_publisher.rb

# The publisher is responsible for configuring and formatting
# the pub/sub message.
class UserPublisher
  include Cloudenvoy::Publisher

  cloudenvoy_options topic: 'system-users'

  # Publishers must at least implement the `payload` method,
  # which specifies how the message should be formatted.
  def payload(user)
    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end
```

Then in your user model you can do the following:
```ruby
# app/users/user_publisher.rb

class User < ApplicationRecord
  after_create :publish_user

  private

  # Publish users after they have been created
  def publish_user
    UserPublisher.publish(self)
  end
end
```

### Publisher implementation layout

A full publisher implementation looks like this:
```ruby
class MyPublisher
  include Cloudenvoy::Publisher

  # The topic option defines the default topic messages will be
  # sent to. The publishing topic can be overriden on a per message
  # basis. See the #topic method below.
  cloudenvoy_options topic: 'my-topic'

  # Evaluate the topic at runtime based on publishing arguments.
  # Returning `nil` makes the publisher use the default topic
  # defined via cloudenvoy_options.
  #
  # Note: runtime topics do not get created by the rake tasks. You
  # must create them manually at this stage.
  def topic(arg1, arg2)
    arg1 == 'other' ? 'some-other-topic' : nil
  end

  # Attach pub/sub attributes to the message. Pub/sub attributes
  # can be used for message filtering.
  def metadata(arg1, arg2)
    { reference: "#{arg1}_#{arg2}" }
  end

  # Publishers must at least implement the `payload` method,
  # which specifies how arguments should be transformed into
  # a message payload (Hash or String).
  def payload(arg1, arg2)
    {
      foo: arg1,
      bar: arg2
    }
  end

  # This hook is invoked when the message fails to be formatted and published.
  # If something wrong happens in the methods above, this hook will be triggered.
  def on_error(error)
    logger.error("Oops! Something wrong happened!")
  end
end
```

## Receiving messages

After you have subscribed to a topic, Pub/Sub sends messages to your application via webhook on the `/cloudenvoy/receive` endpoint. Cloudenvoy then automatically dispatches the message to the right subscriber for processing.

Following up on the previous user publishing example, you might define the following subscriber in another Rails application:

```ruby
# app/subscribers/user_subscriber.rb

class UserSubscriber
  include Cloudenvoy::Subscriber

  # Subscribers can subscribe to multiple topics
  #
  # You can subscribe to multiple topics:
  # > cloudenvoy_options topics: ['system-users', 'events']
  #
  # You can specify subscription options for each topic
  # by passing a hash (target: v0.2.0)
  #
  # > cloudenvoy_options topics: ['system-users', { name: 'events', retain_acked: true }]
  #
  # See the Pub/Sub documentation of the list of available subscription options: 
  # https://googleapis.dev/ruby/google-cloud-pubsub/latest/Google/Cloud/PubSub/Topic.html#subscribe-instance_method
  #
  cloudenvoy_options topic: 'system-users'

  # Create the user locally if it does not exist already
  #
  # A message has the following attributes:
  #   id: the pub/sub message id
  #   payload: the content of the message (String or Hash)
  #   metadata: the pub/sub message attributes
  #   sub_uri: the pub/sub subscription URI
  #   topic: the topic the message comes from
  #
  def process(message)
    payload = message.payload

    User.create_or_find_by(system_id: payload['id']) do |u|
      u.first_name = payload['name']
      u.email = payload['email']
    end
  end

  # This hook will be invoked if the message processing fails
  def on_error(error)
    logger.error("The following error happened: #{error}")
  end
end
```

## Logging
There are several options available to configure logging and logging context.

### Configuring a logger
Cloudenvoy uses `Rails.logger` if Rails is available and falls back on a plain ruby logger `Logger.new(STDOUT)` if not.

It is also possible to configure your own logger. For example you can setup Cloudenvoy with [semantic_logger](http://rocketjob.github.io/semantic_logger) by doing the following in your initializer:
```ruby
# config/initializers/cloudenvoy.rb

Cloudenvoy.configure do |config|
  config.logger = SemanticLogger[Cloudenvoy]
end
```

### Logging context
Cloudenvoy provides publisher/subscriber contextual information to the `logger` methods.

For example:
```ruby
# app/subscribers/dummy_subscriber.rb

class DummySubscriber
  include Cloudenvoy::Subscriber

  cloudenvoy_options topics: ['my-topic']

  def process(message)
    logger.info("Subscriber processed with #{message.inspect}. This is working!")
  end
end
```

Will generate the following log with context `{:id=>..., :metadata=>..., :topic=>...}`
```log
[Cloudenvoy][DummySubscriber][1501678353930997] Subscriber processed with ###. This is working! -- {:id=>"1501678353930997", :metadata=>{"some"=>"meta"}, :topic=>"my-topic"}
```

The way contextual information is displayed depends on the logger itself. For example with [semantic_logger](http://rocketjob.github.io/semantic_logger) contextual information might not appear in the log message but show up as payload data on the log entry itself (e.g. using the fluentd adapter).

Contextual information can be customised globally and locally using a log context_processor. By default the loggers are configured this way:
```ruby
# Publishers
Cloudenvoy::PublisherLogger.log_context_processor = ->(publisher) { publisher.message&.to_h&.slice(:id, :metadata, :topic) || {} }

# Subscribers
Cloudenvoy::SubscriberLogger.log_context_processor = ->(subscriber) { subscriber.message.to_h.slice(:id, :metadata, :topic) }
```

You can decide to add a global identifier for your publisher logs using the following:
```ruby
# config/initializers/cloudenvoy.rb

Cloudenvoy::PublisherLogger.log_context_processor = lambda { |publisher|
  publisher.message.to_h.slice(:id, :metadata, :topic).merge(app: 'my-app')
}
```

You could also decide to log all available context - including the message payload - for specific subscribers only:
```ruby
# app/subscribers/full_context_subscriber.rb

class FullContextSubscriber
  include Cloudenvoy::Subscriber

  cloudenvoy_options topics: ['my-topic'], log_context_processor: ->(s) { s.message.to_h }

  def process(message)
    logger.info("This log entry will have full context!")
  end
end
```

See the [Cloudenvoy::Publisher](lib/cloudenvoy/publisher.rb), [Cloudenvoy::Subscriber](lib/cloudenvoy/subscriber.rb) and [Cloudenvoy::Message](lib/cloudenvoy/message.rb) for more information on attributes available to be logged in your `log_context_processor` proc.

## Error Handling

Message failures will return an HTTP error to Pub/Sub and trigger a retry at a later time. By default Pub/Sub will retry sending the message until the acknowledgment deadline expires. A number of retries can be explicitly configured by setting up a dead-letter queue.

### HTTP Error codes

When Cloudenvoy fails to process a message it returns the following HTTP error code to Pub/Sub, based on the actual reason:

| Code | Description |
|------|-------------|
| 204 | The message was processed successfully |
| 404 | The message subscriber does not exist.  |
| 422 | An error occured during the processing of the message (`process` method) |

### Error callbacks

Publishers and subscribers can implement the `on_error(error)` callback to do things when a message fails to be published or received:

E.g.
```ruby
# app/publisher/handle_error_publisher.rb

class HandleErrorPublisher
  include Cloudenvoy::Publisher

  cloudenvoy_options topic: 'my-topic'

  def payload(arg)
    raise(ArgumentError)
  end

  # The runtime error is passed as an argument.
  def on_error(error)
    logger.error("The following error occured: #{error}")
  end
end
```

## Testing
Cloudenvoy provides several options to test your publishers and subscribers.

### Test helper setup
Require `cloudenvoy/testing` in your `rails_helper.rb` (Rspec Rails) or `spec_helper.rb` (Rspec) or test unit helper file then enable one of the two modes:

```ruby
require 'cloudenvoy/testing'

# Mode 1 (default): Push messages to GCP Pub/Sub (env != development)
Cloudenvoy::Testing.enable!

# Mode 2: Push message to in-memory queues. You will be responsible for clearing the
# topic queues using `Cloudenvoy::Testing.clear_all` or `Cloudenvoy::Testing.clear('my-topic')`
Cloudenvoy::Testing.fake!
```

You can query the current testing mode with:
```ruby
Cloudenvoy::Testing.enabled?
Cloudenvoy::Testing.fake?
```

Each testing mode accepts a block argument to temporarily switch to it:
```ruby
# Enable fake mode for all tests
Cloudenvoy::Testing.fake!

# Enable real mode temporarily for a given test
Cloudenvoy.enable! do
   MyPublisher.publish(1,2)
end
```

Note that extension middlewares - if any has been registered - run in test mode. You can disable middlewares in your tests by adding the following to your test helper:
```ruby
# Remove all middlewares
Cloudenvoy.configure do |c|
  c.publisher_middleware.clear
  c.subscriber_middleware.clear
end

# Remove all specific middlewares
Cloudenvoy.configure do |c|
  c.publisher_middleware.remove(MyMiddleware::Publisher)
  c.subscriber_middleware.remove(MyMiddleware::Subscriber)
end
```

### In-memory queues
The `fake!` modes uses in-memory queues for topics, which can be queried and controlled using the following methods:

```ruby
# Clear all messages across all topics
Cloudenvoy::Testing.clear_all

# Remove all messages in a given topic
Cloudenvoy::Testing.clear('my-top')

# Get all messages for a given topic
Cloudenvoy::Testing.queue('my-top')
```

### Unit tests
Below are examples of rspec tests. It is assumed that `Cloudenvoy::Testing.fake!` has been set in the test helper.

**Example 1**: Testing publishers
```ruby
describe 'message publishing'
  subject(:publish_message) { MyPublisher.publish(1,2) }

  let(:queue) { Cloudenvoy::Testing.queue('my-topic') }

  it { expect { publish_message }.to change(queue, :size).by(1) }
  it { is_expected.to have_attributes(payload: { 'foo' => 'bar' }) }
end
```

**Example 2**: Testing subscribers
```ruby
describe 'message processing'
  subject { VerifyDataViaApiSubscriber.new(message: message).execute } }

  let(:message) { Cloudenvoy::Message.new(payload: { 'some' => 'payload' }) }

  before { expect(MyApi).to receive(:fetch).and_return([]) }
  it { is_expected.to be_truthy }
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keypup-io/cloudenvoy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/keypup-io/cloudenvoy/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cloudenvoy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/keypup-io/cloudenvoy/blob/master/CODE_OF_CONDUCT.md).
