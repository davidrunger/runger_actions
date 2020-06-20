[![codecov](https://codecov.io/gh/davidrunger/active_actions/branch/master/graph/badge.svg)](https://codecov.io/gh/davidrunger/active_actions)

# ActiveActions

Organize and validate the business logic of your Rails application with this combined form object /
command object.

## Installation

Add the gem to your application's `Gemfile`. Because the gem is not released via RubyGems, you will
need to install it from GitHub.

```rb
gem 'active_actions', git: 'https://github.com/davidrunger/active_actions.git'
```

You'll also need to list one of `active_actions`'s dependencies,
[`shaped`](https://github.com/davidrunger/shaped/), in your `Gemfile`, too:

```rb
gem 'shaped', git: 'https://github.com/davidrunger/shaped.git'
```

And then execute:

```
$ bundle install
```

## Usage

Create a new subdirectory within the `app/` directory in your Rails app: `app/actions/`.

Create an `app/actions/application_action.rb` file with this content:
```rb
# app/actions/application_action.rb

class ApplicationAction < ActiveActions::Base
end
```

Then, you can start creating actions. Here's an example:
```rb
# app/actions/send_text_message.rb

class SendTextMessage < ApplicationAction
  requires :message_body, String, length: { minimum: 3 } # don't send any super short messages
  requires :user, User do
    validates :phone, presence: true, format: { with: /[[:digit:]]{11}/ }
  end

  fails_with :nexmo_request_failed

  def execute
    if ENV['NEXMO_API_KEY'].present?
      send_via_nexmo!
    else
      log_message
    end
  end

  private

  def send_via_nexmo!
    nexmo_response = NexmoClient.send_text!(number: user.phone, message: message_body)
    if !nexmo_response.success?
      result.nexmo_request_failed!
    end
  end

  def log_message
    puts(<<~LOG)
      NEXMO_API_KEY is blank; message would have been:
      ~~~~~~~~~~~~~~~~~~~~~
      #{message_body}
      =====================
    LOG
  end
end
```

Then, you can use that action anywhere in your code, such as in a controller, as illustrated below.
(The most likely place to use an action is in a controller, but you can execute an action from
anywhere in your codebase; you are not limited to invoking actions from controller actions.)

```rb
# app/controllers/api/text_messages_controller.rb

class Api::TextMessagesController < ApplicationController
  def create
    send_message_action =
      SendTextMessage.new(
        user: current_user,
        message_body: "Hello! This message was generated at #{Time.current}.",
      )

    if !send_message_action.valid?
      # We'll enter this block if one of the ActiveRecord inputs (`user`, in this case) for the
      # action doesn't meet the required validations, e.g. if the user's `phone` is blank.
      render json: { error: send_message_action.errors.full_messages.join(', ') }, status: 400
      return
    end

    result = send_message_action.run
    if result.success?
      head :created
    elsif result.nexmo_request_failed?
      render json: { error: 'An error occurred when sending the text message' }, status: 500
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, `bundle install`, update `CHANGELOG.md`, commit
the changes with a message like `Prepare to release v0.1.1`, and then run `bin/release`, which will
create a git tag for the version and push git commits and tags.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
