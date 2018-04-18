# Outkit API Client
This is the official Elixir client for the [Outkit](https://outkit.io/) API.

## Installation
First, add Outkit to your `mix.exs` dependencies:

```elixir
def deps do
  [{:outkit, "~> 0.0.1"}]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

Add `:outkit` to your list of applications if using Elixir 1.3 or lower.

```elixir
defp application do
  [applications: [:outkit]]
end
```

## Configuration

In one of your configuration files, include your Outkit API credentials like this:

```elixir
config :outkit,
  key: "OUTKIT_API_KEY",
  secret: "OUTKIT_API_SECRET",
  passphrase: "OUTKIT_API_PASSPHRASE"
```

## Usage

### General
All functions of the API client take an `%Outkit.Client{}` struct as the first argument. This struct contains auth info and options.
If you don’t supply a client as the first argument, the library will auto-build one from the configuration and use it automatically. 
So in the following example the two methods are identical, provided that you have specified the same settings in your configuration 
files as those passed to the `Outkit.Client.new` function:

```elixir
# Method one
Outkit.Message.create(message)

# Method two
client = Outkit.Client.new(key: "my-key", secret: "my-secret", passphrase: "my-passphrase")
Outkit.Message.create(client, message)
```

This gives you complete flexibility in terms of how you want to use Outkit - one static configuration for your entire app
or several clients that can be dynamically configured at runtime.

### Submitting a message
Submitting a message for rendering and/or delivery will return a message record with the Outkit ID and the status set to `received`
(as well as a few other properties that can be determined at creation time). The API call returns as soon as the message 
is saved on our servers, it does not wait for rendering or delivery to take place (by default - see the section on synchronous
processing below). You can retrieve the status of a message at any time. We also support webhook notifications on status changes.

```elixir
# Create a message
{:ok, message} = Outkit.Message.create(%{
  type: "email",                   # Message type - 'email' and 'sms' currently supported
  project: "my-project",           # Outkit project identifier (managed through our web UI)
  template: "my-template",         # Template identifier (managed through our web UI)
  subject: "Welcome, Jane!",       # Email subject (optional, can also be set in the template or omitted for SMS messages)
  to: "some.name@example.com",     # Recipient address (and optional name)
  from: "other.name@example.com",  # Sender address (and optional name)
  data: %{
      name: "John Doe",
      # ...
      # Add the values for any variables used in the template here
  },
})
```

### Retrieving a message
You can retrieve the status and data of a message at any time. After the message has been rendered, we will also return the 
applicable rendered fields (`subject`, `html_body` and `text_body` for emails, `text_body` for SMS messages) so that you 
can see exactly what was/will be sent.

```elixir
{:ok, message} = Outkit.Message.get("some-id")
```

## Return values
The return value for all API functions in this library is always a tuple:

```elixir
# Either
{:ok, some_data}

# or
{:error, error_message}
```

The data part of the tuple will (by default) contain only the _actual_ data returned from the API, converted to 
Elixir data structures. So both `Outkit.Message.get/1` and `Outkit.Message.create/1` return a `%Outkit.Message{}` 
struct, like so

```elixir
%Outkit.Message{
  type: "email"
  project: "acme-project", 
  template: "welcome", 
  html_body: "... rendered HTML ...",
  text_body: "... rendered plain text ...",
  backend_response: %{             # Note that child Maps are regular maps with string keys
    "normalized_id" => "abc123",
    ...
  }
  ...
}
```

If you need access to the full response from our API (including HTTP headers, HTTP status code etc.), you can set the 
`return_response` in the `opts` key on the client, like so:

```elixir
client = Outkit.Client.new(opts: [return_response: true])   # Or you could do the same in your configuration
{:ok, response} = Outkit.Message.create(client, message)
```

The `response` variable will contain something like this:

```elixir
%{
  body: %{...}, 
  raw_body: "...",
  headers: %{...},
  status_code: 200,
}
```

You’d find the actual data in `response.body["data"]`. Note that the data is just regular Lists or Maps with string keys - no structs.


## Rendering a message
To support the use case of _rendering_ a message using the Outkit infrastructure, but sending it yourself, you can specify
`render_only: true` in the message record. You may also want to set `sync: true` in these cases - see the next section.

Once the message has been rendered, its data will contain a `text_body` field (all types), and `subject` and `html_body` 
fields for emails. These can then be fed directly to, say, a Mailgun client or SMTP server. See details below.

## Synchronous processing
For some use cases (sending emails from scripts, using Outkit as a renderer etc.), it can be desirable to have the
API calls operate synchronously - ie. perform rendering/delivery immediately instead of queueing messages, and return the 
rendered message and (optionally) its delivery status in the data from the API call. This can be accomplished by setting 
`sync: true` in the submitted message. 

Note that this will incur additional costs (see [our pricing page](https://outkit.io/pricing) for details), and that each 
Outkit customer is only allowed a limited number of such requests (currently 100.000 per month), since they are more 
difficult and costly for us to scale. Customers that need additional synchronous requests can contact support to have their 
monthly limit raised. We expect to raise the default limit significantly when we more usage data.


## Message lifecycle

Submitted messages typically go through the following stages, which are reflected in the `status` field:

* `received` - The message has been received and saved in our datastore, where it awaits further processing
* `queued_for_rendering` - The message has been queued for rendering
* `rendered` - The subject and HTML/text of the template have been rendered and merged with the submitted data
* `queued_for_delivery` - The message has been queued for delivery
* `delivered` - Message has been successfully delivered to the backend

Typically, a message will go through all stages in a matter of milliseconds, but it can sometimes take a little longer. 

Note that different message can have different statuses. For example, a message with the `render_only` flag set will
never be queued for delivery or delivered. Messages that supply their own `text_body` and `html_body` instead of
using a template will never be rendered, only delivered.

Note that the `delivered` status does not necessarily mean that the message has been delivered to the *end user*. Once the
backend has accepted the message, it’s up to the backend to perform final delivery. Most backends offer webhooks if you 
need confirmation of the actual delivery. 

There are some additional statuses your message can have, in case of errors and problems:

* `render_error` - We were unable to render the template with the submitted data
* `backend_error` - We encountered an error when trying to submit the message to the configured backend
* `internal_error` - There was an unrecoverable problem on our end (should be very rare)

If the message has any of these statuses, there will be more information in the `status_message` field. Also, you
can inspect the full backend response in the `response` field.

All messages have a `done` flag (true or false) which indicate whether we have finished processing it. Nothing more
will happen to a message once it is done, regardless of its status.


## A note on function names
The functions names for messages (`get` and `create`) are deliberately generic, to align them with future expansions 
of the API (say, `Outkit.Project.create`). So even though you might feel like you are _submitting_ or _sending_ a message 
(and we often use terms like that in our own docs), in API terms you are always just `create`-ing it.

You’ll probably wrap our functions in your own `MyApp.send_sms` or `MyApp.enqueue_email` or whatever anyway, so it 
shouldn’t be much of an issue. We feel that when dealing with APIs and their clients, consistency trumps linguistic 
accuracy.

## TODO
* Write proper tests with mocks (the current tests run "live" against our dev servers)
