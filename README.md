[![codecov](https://codecov.io/gh/davidrunger/active_actions/branch/master/graph/badge.svg)](https://codecov.io/gh/davidrunger/active_actions)
[![Build Status](https://travis-ci.com/davidrunger/active_actions.svg?branch=master)](https://travis-ci.com/davidrunger/active_actions)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=davidrunger/active_actions)](https://dependabot.com)
![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/davidrunger/active_actions?include_prereleases)

# ActiveActions

Organize and validate the business logic of your Rails application with this combined form object /
command object.

# Table of Contents

<!--ts-->
   * [ActiveActions](#activeactions)
   * [Table of Contents](#table-of-contents)
   * [Installation](#installation)
   * [Usage in general](#usage-in-general)
      * [Setup](#setup)
      * [Generate your actions](#generate-your-actions)
      * [Define your actions](#define-your-actions)
      * [Invoke your actions](#invoke-your-actions)
   * [Usage in specific](#usage-in-specific)
      * [An #execute instance method is required!](#an-execute-instance-method-is-required)
      * [Action class methods](#action-class-methods)
         * [::requires](#requires)
            * [Specifying the expected shape of a Hash input](#specifying-the-expected-shape-of-a-hash-input)
            * [Specifying ActiveModel-style validations](#specifying-activemodel-style-validations)
            * [Specifying arbitrary input "shapes" by providing a callable object](#specifying-arbitrary-input-shapes-by-providing-a-callable-object)
            * [Specifying validations for ActiveRecord inputs](#specifying-validations-for-activerecord-inputs)
         * [::returns](#returns)
            * [The result object](#the-result-object)
            * [All promised values must be returned](#all-promised-values-must-be-returned)
            * [Validating the "shape" of returned values](#validating-the-shape-of-returned-values)
         * [::fails_with](#fails_with)
   * [Alternatives](#alternatives)
   * [Status / Context](#status--context)
   * [Development](#development)
   * [License](#license)

<!-- Added by: david, at: Thu Jan 21 20:53:08 PST 2021 -->

<!--te-->

# Installation

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

# Usage in general

## Setup

Create a new subdirectory within the `app/` directory in your Rails app: `app/actions/`.

Create an `app/actions/application_action.rb` file with this content:
```rb
# app/actions/application_action.rb

class ApplicationAction < ActiveActions::Base
end
```

## Generate your actions

This gem provides a Rails generator. For example, running:

```
bin/rails g active_actions:action Users::Create
```

will create an empty action in `app/actions/users/create.rb`.

## Define your actions

Then, you can start defining actions. Here's an example:
```rb
# app/actions/send_text_message.rb

class SendTextMessage < ApplicationAction
  requires :message_body, String, length: { minimum: 3 } # don't send any super short messages
  requires :user, User do
    validates :phone, presence: true, format: { with: /[[:digit:]]{11}/ }
  end

  returns :cost, Float, numericality: { greater_than_or_equal_to: 0 }
  returns :nexmo_id, String, presence: true

  fails_with :nexmo_request_failed

  def execute
    nexmo_response = NexmoClient.send_text!(number: user.phone, message: message_body)
    if nexmo_response.success?
      nexmo_response_data = nexmo_response.parsed_response
      result.cost = nexmo_response_data['cost']
      result.nexmo_id = nexmo_response_data['message-id']
    else
      result.nexmo_request_failed!
    end
  end
end
```

## Invoke your actions

Once you have defined one or more actions, you can invoke the action(s) anywhere in your code, such
as in a controller, as illustrated below.

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
      Rails.logger.info("Sent message with Nexmo id #{result.nexmo_id} at a cost of #{result.cost}")
      head :created
    elsif result.nexmo_request_failed?
      render json: { error: 'An error occurred when sending the text message' }, status: 500
    end
  end
end
```

You aren't limited to invoking actions from a controller action, though; you can invoke an action
from anywhere in your code.

One good place to invoke an action is from within *another* action. For a complex or multi-step
process, you might want to break that process down into several "sub actions" that can be invoked
from the `#execute` method of a coordinating "parent action".

# Usage in specific

## An `#execute` instance method is required!

The only real requirement for an action is that it implements an `#execute` instance method.

```rb
class DoSomething < ApplicationAction
  def execute
    # you MUST write an #execute instance method for your action
  end
end
```

Although all actions must implement an `#execute` instance method, you should generally not invoke
that method directly in your application code. Instead, call `#run` on an instance of the class:

```rb
# this will run the DoSomething#execute instance method
DoSomething.new.run
```

## Action class methods

When defining an action class, these three class methods are available:
1. `requires`
2. `returns`
3. `fails_with`

Those class methods are all optional, though. We'll detail/illustrate their usage below.

### `::requires`

The `::requires` class method declares the necessary, expected inputs that are needed in order to
execute an action.

An action can have zero, one, or more `requires` statements.

An action that requires no input values will have no `requires` statements:

```rb
class PrintCurrentTime < ApplicationAction
  def execute
    puts("The current time is #{Time.now}.")
  end
end

PrintCurrentTime.new.run
# => prints "The current time is 2020-06-20 03:25:14 -0700."
```

Most actions probably will take one or more inputs, though. Here's an example of an action with one
`requires` statement:

```rb
class PrintDoubledNumber < ApplicationAction
  requires :number, Numeric

  def execute
    puts("#{number} doubled is #{number * 2}")
  end
end

PrintDoubledNumber.new(number: 8).run
# => prints "8 doubled is 16"
```

In the example above, because the `PrintDoubledNumber` action class declares `requires :number`, a
`#number` instance method is available for all instances of that action class. This `#number`
instance method is used within the `PrintDoubledNumber#execute` action.

All subsequent arguments given to `requires` are used to define a "shape" via the [`shaped`
gem](https://github.com/davidrunger/shaped/).

The simplest way to define the expected "shape" of a required action parameter is probably to
declare its expected class, as illustrated above (where we specified that the `number` input
parameter must be an instance of `Numeric`). However, the `shaped` gem supports a wide variety of
ways to specify the expected "shape" of an input. A few additional examples are shown below; see the
[`shaped` documentation](https://github.com/davidrunger/shaped/) for more possibilities.

#### Specifying the expected shape of a Hash input

```rb
class PrintNameAndEmail < ApplicationAction
  # The `{ email: String, phone: String }` argument specifies the expected shape of `user_data`.
  requires :user_data, { name: String, email: String }

  def execute
    puts("The email of #{user_data[:name]} is #{user_data[:email]}.")
  end
end

PrintNameAndEmail.new(user_data: { name: 'Tom', email: 'tommy@example.com' }).run
# => prints "The email of Tom is tommy@example.com."

# The name and email keys are strings; they are supposed to be symbols.
PrintNameAndEmail.new(user_data: { 'name' => 'Thomas', 'email' => 'tommy@example.com' })
# => raises ActiveActions::TypeMismatch

# The `:name` key is missing in the `user_data` hash.
PrintNameAndEmail.new(user_data: { email: 'tommy@example.com' })
# => raises ActiveActions::TypeMismatch
```

#### Specifying ActiveModel-style validations

```rb
class PrintEmail < ApplicationAction
  requires :email, String, format: { with: /.+@.+\..+/ }, length: { minimum: 6 }

  def execute
    puts("The email is '#{email}'.")
  end
end

PrintEmail.new(email: 'jefferson@example.com').run
# => prints "The email is 'jefferson@example.com'."

# This email doesn't match the specified regex
PrintEmail.new(email: 'Thomas Jefferson')
# => raises ActiveActions::TypeMismatch

# This email is too short
PrintEmail.new(email: 'a@b.c')
# => raises ActiveActions::TypeMismatch
```

#### Specifying arbitrary input "shapes" by providing a callable object

You can leverage `shaped`'s [`Callable` shape
type](https://github.com/davidrunger/shaped/#shapedshapescallable) by providing any object that
responds to `#call` (such as a lambda). This allows you unlimited flexibility to define requirements
for the action's input(s).

```rb
class PrintSmallEvenNumber < ApplicationAction
  requires :small_even_number, ->(number) { (0..6).cover?(number) && number.even? }

  def execute
    puts("#{small_even_number} is a small, even number.")
  end
end

PrintSmallEvenNumber.new(small_even_number: 2).run
# => prints "2 is a small, even number."

# This number is not even
PrintSmallEvenNumber.new(small_even_number: 3).run
# => raises ActiveActions::TypeMismatch

# This number is not small
PrintSmallEvenNumber.new(small_even_number: 200).run
# => raises ActiveActions::TypeMismatch
```

#### Specifying validations for ActiveRecord inputs

When declaring a `requires` where the input is specified (via the second argument to `requires`) to
be a class that inherits from `ActiveRecord::Base`, there are a few special things that happen:
1. You can provide a **validation block** for the ActiveRecord object. Within this block, you can
   specify validations on attributes of that ActiveRecord model.
2. You can check, by calling `valid?` on an instance of the action, whether the ActiveRecord
   object(s) that are inputs for the action meet the **validation block** validations.
3. You can access any validation errors (from the **validation block**) via the `#errors` method of
   the action instance.
4. You can execute the action instance via `run!` rather than `run`; this will raise an exception
   (and not run the `#execute` method) if any of the validations from a **validation block** are not
   met.

```rb
class PrintFirstAndLastName < ApplicationAction
  requires :user, User do
    validates :name, format: { with: /.+ .+/ }
  end

  def execute
    name_parts = user.name.split(' ')
    puts("First name: #{name_parts.first}. Last name: #{name_parts.last}")
  end
end

user = User.find(1)
user.is_a?(ActiveRecord::Base)
# => true
user.name
# => "David Runger"
action = PrintFirstAndLastName.new(user: user)
action.valid?
# => true
action.errors.to_hash
# => {}
action.run!
# => prints "First name: David. Last name: Runger"

user = User.find(2)
user.name
# => "Cher"
action = PrintFirstAndLastName.new(user: user)
action.valid?
# => false
action.errors.to_hash
# => {:name=>["is invalid"]}
action.run!
# => raises ActiveActions::InvalidParam
```

### `::returns`

The `::returns` class method describes the value(s) that an action promises to return (if any).

As with `requires`, an action can have zero, one, or more `returns` statements.

An action that is used for its "side effects," such as most of the examples above that use `puts` to
print output, will probably not have any `returns` statements.

However, if you want the action to return object(s)/data to other parts of your code, then you'll
need to declare those return values using the `returns` class method.

Here's an example:

```rb
class MultiplyNumber < ApplicationAction
  requires :input_number, Numeric

  returns :doubled_number, Numeric
  returns :tripled_number, Numeric

  def execute
    result.doubled_number = input_number * 2
    result.tripled_number = input_number * 3
  end
end

multiply_result = MultiplyNumber.new(input_number: 1.5).run
multiply_result.class
# => MultiplyNumber::Result
puts("The number doubled is #{multiply_result.doubled_number}")
# => prints "The number doubled is 3.0"
puts("The number tripled is #{multiply_result.tripled_number}")
# => prints "The number tripled is 4.5"
```

#### The `result` object

We can see in the example above that `MultiplyNumber#execute` references `result`, which is an
object provided automatically to action instances. Because the `MultiplyNumber` action declares
`returns :doubled_number` and `returns :tripled_number`, the `result` object automatically has
`#doubled_number=` and `#tripled_number=` writer methods, which can (and should) be invoked by the
action instance in order to set those values on the `result` object.

When we call `MultiplyNumber.new(input_number: 1.5).run`, the return value of `#run` is the action's
`result` object. Outside of the action, we can then access the return values that were set within
the action's `#execute` method; we do this via the `#doubled_number` and `#tripled_number` reader
methods that are defined on the result object (which we captured in a local variable called
`multiply_result`).

#### All promised values must be returned

If an action fails to set any promised return values on the `result` object, then an error will be
raised when `#run` is called:

```rb
class MultiplyNumber < ApplicationAction
  requires :input_number, Numeric

  returns :doubled_number, Numeric
  returns :tripled_number, Numeric

  def execute
    # PROBLEM BELOW! An error will be raised when this action is executed,
    # because we fail to set a `doubled_number` return value.

    # result.doubled_number = input_number * 2
    result.tripled_number = input_number * 3
  end
end

multiply_result = MultiplyNumber.new(input_number: 10).run
# => raises ActiveActions::MissingResultValue
```

#### Validating the "shape" of returned values

As with the `requires` action class method, the "shape" of the promised return values declared via
`returns` can be described via the arguments to `requires`, which are passed to the [`shaped`
gem](https://github.com/davidrunger/shaped/). Leveraging this functionality allows you to ensure
that your action is providing the expected type of return values.

```rb
class UppercaseEmail < ApplicationAction
  requires :email, String, format: { with: /.+@.+/ }

  returns :uppercased_email, String, format: { with: /[A-Z]+@[A-Z.]+/ }

  def execute
    result.uppercased_email = email.upcase
  end
end

UppercaseEmail.new(email: 'david@protonmail.com').run.uppercased_email
# => "DAVID@PROTONMAIL.COM"
```

If an action attempts to set a return value that doesn't match the specified "shape" for that return
value, then an `ActiveActions::TypeMismatch` error will be raised:

```rb
class UppercaseEmail < ApplicationAction
  requires :email, String, format: { with: /.+@.+/ }

  returns :uppercased_email, String, format: { with: /[A-Z]+@[A-Z.]+/ }

  def execute
    # PROBLEM BELOW! This action is supposed to _upcase_ the email, not downcase it!
    result.uppercased_email = email.downcase
  end
end

UppercaseEmail.new(email: 'david@protonmail.com').run
# => raises ActiveActions::TypeMismatch
```

### `::fails_with`

The `::fails_with` class method can be used to enumerate possible "failure modes" for the action.

As with `requires` and `returns`, an action can have zero, one, or more `fails_with` statements.

Generally, it's best to try to write actions in a way such that we don't expect any failures, but
sometimes there are things outside of our control; in such cases, using `fails_with` to list these
possible points of failure is a good idea. For example, a call to an external API might time out or
receive a 500 error response.

Here's a (contrived) example with one `fails_with` declaration:

```rb
class PrintRandomNumberAboveFive < ApplicationAction
  fails_with :number_was_too_small

  def execute
    random_number = rand(10)
    if random_number > 5
      puts(random_number)
    else
      result.number_was_too_small!
    end
  end
end

result = PrintRandomNumberAboveFive.new.run
# => prints "9" (sometimes)
result.success?
# => true
result.number_was_too_small?
# => false
```

In the case above, we didn't encounter the error condition, which we can verify via the `#success?`
and `#number_was_too_small?` methods on the result. `#success?` is available on all action results,
and `#number_was_too_small?` is available for this particular action result because the action class
declares `fails_with :number_was_too_small`.

And here's what a failure case would look like:

```rb
result = PrintRandomNumberAboveFive.new.run
# => [doesn't print anything, if the random number is <= 5]
result.success?
# => false
result.number_was_too_small?
# => true
```

In this case, we entered the `else` branch of the action's `#execute` method and called the
`result.number_was_too_small!` method (made available automatically because of the class's
`fails_with :number_was_too_small` declaration). Since we called the `result.number_was_too_small!`
method, indicating that that failure mode occurred when executing the action, `#success?` returns
`false` and `#number_was_too_small?` returns `true`.

# Alternatives

This project is not the first of its kind!

Here are a few similar projects:
* [`interactor`](https://github.com/collectiveidea/interactor)
* [`active_interaction`](https://github.com/AaronLasseigne/active_interaction)
* [`mutations`](https://github.com/cypriss/mutations)
* [`service_actor`](https://github.com/sunny/actor)

# Status / Context

I wouldn't recommend using this gem in production. It's very new (i.e. probably rough around the
edges, subject to significant changes at a relatively rapid rate, and arguably somewhat feature
incomplete) and I am not committed to maintaing the gem.

I mostly built this gem because I wasn't _quite_ satisfied with any of the above alternatives that I
knew about at the time that I decided to start building it. I built this gem mostly to scratch my
own itch and for the sake of exploring this problem space a little bit.

I am actively using this gem in the small Rails application that hosts my personal website and apps;
you can check out its [`app/actions/`
directory](https://github.com/davidrunger/david_runger/tree/master/app/actions) if you are
interested in seeing some real-world use cases.

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

# License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
