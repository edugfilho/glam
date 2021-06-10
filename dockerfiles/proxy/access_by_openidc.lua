local cjson = require("cjson")

-- configs
local opts = {
    claim_groups = ngx.var.oidc_claim_groups or "https://sso.mozilla.com/claim/groups",
    client_id = ngx.var.oidc_client_id,
    discovery = ngx.var.oidc_discovery or "https://auth.mozilla.auth0.com/.well-known/openid-configuration",
    logout_path = ngx.var.oidc_logout_path,
    redirect_uri = ngx.var.oidc_redirect_uri,
    scope = ngx.var.oidc_scope or "openid email profile",
    token_endpoint_auth_method = "client_secret_post",
}

-- we support the old client secret flow, as well as the PKCE flow as
-- recommended in OAuth 2.1, if oidc_client_secret isn't set, assume PKCE
if ngx.var.oidc_client_secret then
    opts.client_secret = ngx.var.oidc_client_secret
else
    opts.use_pkce = true
end

if ngx.var.oidc_hd then
    opts.authorization_params = {hd=ngx.var.oidc_hd}
end

-- call authenticate for OpenID Connect user authentication
local res, err, target, session = require("resty.openidc").authenticate(opts)
session:close() -- explicitly close session to prevent timeouts around locking

if err then
    ngx.status = 500
    ngx.say(err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- require hd matches if specified
if ngx.var.oidc_hd and res.id_token.hd ~= ngx.var.oidc_hd then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- if at least one email or group is specified, require user is in one of them
local validate_user, valid_user

for _, email in (ngx.var.oidc_emails or ""):gmatch("([^,]+),?") do
    validate_user = true
    if res.user.email == email then
        valid_user = true
        break
    end
end

for _, group in (ngx.var.oidc_groups or ""):gmatch("([^,]+),?") do
    validate_user = true
    for _, usergroup in res.user.groups do
        if usergroup == group then
            valid_user = true
            break
        end
    end
end

if validate_user and not valid_user then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- delete OIDC* headers from the request
for key, _ in pairs(ngx.req.get_headers()) do
    if key:sub(1,4):upper() == "OIDC" then
        ngx.req.clear_header(key)
    end
end

-- set headers with user info
ngx.req.set_header("REMOTE-USER", res.id_token.user_id)
ngx.req.set_header("OIDC-CLAIM-ACCESS-TOKEN", res.access_token)

local function build_headers(t, name)
  for k,v in pairs(t) do
    k = k:gsub("_", "-")
    -- unpack tables
    if type(v) == "table" then
      local j = cjson.encode(v)
      ngx.req.set_header("OIDC-CLAIM-"..name..k, j)
    else
      ngx.req.set_header("OIDC-CLAIM-"..name..k, tostring(v))
    end
  end
end

build_headers(res.id_token, "ID-TOKEN-")
build_headers(res.user, "USER-PROFILE-")

-- Flat groups, useful for some RP's that won't read JSON
local usergroup
if res.user.groups then
    usergroup = res.user.groups
else
    usergroup = res.user[opts.claim_groups]
end

if type(usergroup) == "table" then
  ngx.req.set_header("REMOTE-GROUPS", table.concat(usergroup, ","))
end
