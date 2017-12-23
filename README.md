# Überauth Tumblr

> Tumblr strategy for Überauth.

_Note_: Sessions are required for this strategy.

## Installation

1. Setup your application at [Tumblr Developers](https://dev.tumblr.com/).

1. Add `:ueberauth_tumblr` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_tumblr, "~> 0.2"},
       {:oauth, github: "tim/erlang-oauth"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_tumblr]]
    end
    ```

1. Add Tumblr to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        tumblr: {Ueberauth.Strategy.Tumblr, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Tumblr.OAuth,
      consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
      consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/tumblr

## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_tumblr/blob/master/LICENSE) for licensing details.

