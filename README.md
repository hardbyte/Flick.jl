Flick.jl

A very basic Julia client for the Flick Electric API.



As flick doesn't (yet) allow developers to register applications you have to use
the app tokens embedded in their client app.


TODO cache

## Usage


You can create a `credentials.json` file if you like, or configure at runtime.

```
{
  "client_id": "le37iwi3qctbduh39fvnpevt1m2uuvz",
  "client_secret": "ignwy9ztnst3azswww66y9vd9zt6qnt",
  "username": "your email here",
  "password": "your password here"
}

```

Note the `client_id` and `client_secret` have been baked into the Flick mobile application and they haven't changed in the last 3 years so you should be fine... However if they change feel free to open a PR to update the defaults here.


```julia
using Flick

config = Flick.get_config("C:/Users/brian/Development/PyFlick/src/config.json")
auth_token = Flick.get_auth_token(config)

```

Alternatively spell it out:

```julia
using Flick

auth_token = Flick.get_auth_token(username, password)
current_price = Flick.get_current_price(auth_token)
println("Current freestyle price in cents: ", current_price)
```

Very much based off the Python client - [PyFlick](https://github.com/driannaude/PyFlick)
