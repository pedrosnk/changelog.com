defmodule Changelog.Plug.Conn do
  import Plug.Conn

  @encryption_salt "8675309"
  @signing_salt "9035768"

  def put_encrypted_cookie(conn, key, value, opts \\ []) do
    now = Timex.DateTime.now
    opts = Keyword.put_new(opts, :max_age, Timex.diff(now, Timex.shift(now, years: 1)))

    encrypted = Plug.Crypto.MessageEncryptor.encrypt_and_sign(
      :erlang.term_to_binary(value),
      generate(conn, @signing_salt, key_opts),
      generate(conn, @encryption_salt, key_opts))

    put_resp_cookie conn, key, encrypted, opts
  end

  def get_encrypted_cookie(conn, key) do
    case conn.cookies[key] do
      nil ->
        nil
      encrypted ->
        {:ok, decrypted} = Plug.Crypto.MessageEncryptor.verify_and_decrypt(
          encrypted,
          generate(conn, @signing_salt, key_opts),
          generate(conn, @encryption_salt, key_opts))

        :erlang.binary_to_term(decrypted)
    end
  end

  defp key_opts do
    [iterations: 1000,
     length: 32,
     digest: :sha256,
     cache: Plug.Keys]
  end

  defp generate(conn, key, key_opts) do
    Plug.Crypto.KeyGenerator.generate(conn.secret_key_base, key, key_opts)
  end
end
