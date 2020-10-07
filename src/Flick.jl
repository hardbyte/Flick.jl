"""

Julia client to get price data from flickelectric.co.nz

"""

module Flick

using HTTP
using JSON
using Dates: Day, Minute, Second
using ExpiringCaches

const SERVER = "https://api.flick.energy"
const MOBILE_ENDPOINT = SERVER * "/customer/mobile_provider"
const PRICE_URL = MOBILE_ENDPOINT * "/price"
const AUTH_URL = SERVER * "/identity/oauth/token"

const DEFAULT_CLIENT_ID = "le37iwi3qctbduh39fvnpevt1m2uuvz"
const DEFAULT_CLIENT_SECRET = "ignwy9ztnst3azswww66y9vd9zt6qnt"

function get_config(filename)
    JSON.parse(open(filename))
end


"""
    get_auth_token()

Using a user's login credentials, and an application id/secret pair from 
Flick, retrieve a authentication token for subsequent API calls.

FYI: Tokens appear to expire in 2 months/60 days.
"""
function get_auth_token(config::Dict)
    get_auth_token(
        get(config, "client_id", DEFAULT_CLIENT_ID),
        get(config, "client_secret", DEFAULT_CLIENT_SECRET),
        config["username"],
        config["password"]
    )
end
get_auth_token(username::String, password::String) = get_auth_token(DEFAULT_CLIENT_ID, DEFAULT_CLIENT_SECRET, username, password)

ExpiringCaches.@cacheable Day(30) function get_auth_token(client_id::String, client_secret::String, username::String, password::String)::String
    headers = ["Content-Type" => "application/x-www-form-urlencoded"]
    payload = Dict(
        "grant_type" => "password",
        "client_id" => client_id,
        "client_secret" => client_secret,
        "username" => username,
        "password" => password
    )
    @debug "⚡ Making authentication call to flick"
    r = HTTP.request("POST", AUTH_URL, headers, HTTP.escapeuri(payload))
    @debug "⚡ Authentication response with status code $(r.status)"

    auth_token = JSON.parse(String(r.body))
    @debug "⚡ Authentication response\n$(auth_token)"

    # We only need the "id_token" string.
    auth_token["id_token"]
end


"""
    get_price_detail()

Returns a Dict from the raw JSON returned by the Flick mobile API.

Contains price broken down into components e.g. the spot price + fees.
"""
function get_price_detail(auth_token)
    flick_api_call(auth_token, PRICE_URL)
end


"""
    flick_api_call(auth_token, url)

Add the Authorization header to a call and parses the assumed JSON response.
"""
function flick_api_call(auth_token, url)::Dict
    @debug "⚡ Making call to flick api @ URL " * url
    headers = [
        "Authorization" => "Bearer $(auth_token)"
    ]
    r = HTTP.request("GET", url, headers)
    @info "⚡ Response received from flick API with status $(r.status)"
    
    JSON.parse(String(r.body))
end

"""
    get_current_price()

Calls are cached in memory for a couple of minutes to avoid hitting the flick api too often.
"""

ExpiringCaches.@cacheable Minute(2) function get_current_price(auth_token::String)::Float64
    flick_price_detail = get_price_detail(auth_token)
    @info "Price detail:\n$(flick_price_detail)"
    parse(Float64, flick_price_detail["needle"]["price"])
end

end # module
