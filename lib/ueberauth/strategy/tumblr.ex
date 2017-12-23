defmodule Ueberauth.Strategy.Tumblr do
  @moduledoc """
  Tumblr Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :id_str

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Tumblr

  @doc """
  Handles initial request for Tumblr authentication.
  """
  def handle_request!(conn) do
    token = Tumblr.OAuth.request_token!([], [redirect_uri: callback_url(conn)])

    conn
    |> put_session(:tumblr_token, token)
    |> redirect!(Tumblr.OAuth.authorize_url!(token))
  end

  @doc """
  Handles the callback from Tumblr.
  """
  def handle_callback!(%Plug.Conn{params: %{"oauth_verifier" => oauth_verifier}} = conn) do
    token = get_session(conn, :tumblr_token)
    case Tumblr.OAuth.access_token(token, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, error} -> set_errors!(conn, [error(error.code, error.reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:tumblr_user, nil)
    |> put_session(:tumblr_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.tumblr_user[uid_field]
  end

  @doc """
  Includes the credentials from the tumblr response.
  """
  def credentials(conn) do
    {token, secret} = conn.private.tumblr_token

    %Credentials{token: token, secret: secret}
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.tumblr_user

    %Info{
      email: user["email"],
      image: user["profile_image_url"],
      name: user["name"],
      nickname: user["screen_name"],
      description: user["description"],
      urls: %{
        Tumblr: "https://tumblr.com/#{user["screen_name"]}",
        Website: user["url"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the tumblr callback.
  """
  def extra(conn) do
    {token, _secret} = get_session(conn, :tumblr_token)

    %Extra{
      raw_info: %{
        token: token,
        user: conn.private.tumblr_user
      }
    }
  end

  defp fetch_user(conn, token) do
    params = [{"include_entities", false}, {"skip_status", true}, {"include_email", true}]
    case Tumblr.OAuth.get("/1.1/account/verify_credentials.json", params, token) do
      {:ok, %{status_code: 401, body: _, headers: _}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %{status_code: status_code, body: body, headers: _}} when status_code in 200..399 ->
        body = Poison.decode!(body)

        conn
        |> put_private(:tumblr_token, token)
        |> put_private(:tumblr_user, body)
      {:ok, %{status_code: _, body: body, headers: _}} ->
        body = Poison.decode!(body)
        error = List.first(body["errors"])
        set_errors!(conn, [error("token", error["message"])])
    end
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end
end
