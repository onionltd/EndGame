-- encryption key and salt must be shared across fronts. salt must be 8 chars
local key = "encryption_key"
local salt = "salt1234"
-- for how long the captcha is valid. 120 sec is for testing, 3600 1 hour should be production.
local session_timeout = 3600

aes = require "resty.aes"
str = require "resty.string"
cook = require "resty.cookie"

aes_128_cbc_sha512x1 = aes:new(key, salt, aes.cipher(128,"cbc"), aes.hash.sha512, 1)

local cookie, err = cook:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    return
end

function fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

caperror = nil

-- check proxy_protocol_addr if present kill circuit if needed
local pa = "no_proxy"
if ngx.var.proxy_protocol_addr ~= nil then
    pa = ngx.var.proxy_protocol_addr
end

-- if "Host" header is invalid / missing kill circuit and return nothing
if in_array(allowed_hosts, ngx.var.http_host) == nil then
    ngx.log(ngx.ERR, "Wrong host (" .. ngx.var.http_host .. ") " .. ngx.var.remote_addr .. "|" .. pa)
    if pa ~= "no_proxy" then
        local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
        if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
        end
    end
    ngx.exit(444)
end

-- only GET and POST requests are allowed the others are not used. HEAD for recon checker
if ngx.var.request_method ~= "POST" and ngx.var.request_method ~= "GET" and ngx.var.request_method ~= "HEAD" then
    ngx.log(ngx.ERR, "Wrong request (" .. ngx.var.request_method .. ") " .. ngx.var.remote_addr .. "|" .. pa)
    if pa ~= "no_proxy" then
        local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
        if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
        end
    end
    ngx.exit(444)
end

-- requests without user-agent are usually invalid
if ngx.var.http_user_agent == nil then
    ngx.log(ngx.ERR, "Missing user agent " .. ngx.var.remote_addr .. "|" .. pa)
    if pa ~= "no_proxy" then
        local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
        if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
        end
    end
    ngx.exit(444)
end

-- POST without referer is invalid. some poorly configured clients may complain about this
if ngx.var.request_method == "POST" and ngx.var.http_referer == nil then
    ngx.log(ngx.ERR, "Post without referer " .. ngx.var.remote_addr .. "|" .. pa)
    if pa ~= "no_proxy" then
        local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
        if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
        end
    end
    ngx.exit(444)
end

-- check cookie support similar to testcookie
if ngx.var.request_method == "GET" then
    local args = ngx.req.get_uri_args()
    if args['tca'] == "1" then
        local field, err = cookie:get("dcap")
        if err or not field then
            ngx.exit(403)   
        end
-- if cookie cannot be decrypted most likely it has been messed with
        local cookdata = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not cookdata then
            ngx.header.content_type = 'text/plain'
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)  
        end      
        cooktest = split(cookdata, "|")[1]
        if cooktest ~= "cap_not_solved" and cooktest ~= "captcha_solved" then
            ngx.exit(403)
        end
    end

-- try to set cookie. max-age is irrelevant as it can be faked and check is done against cookie content anyway. should be set to a large value otherwise it will annoy users
    local field, err = cookie:get("dcap")
    if err then
        local tstamp = ngx.now()
        local plaintext = "cap_not_solved|" .. tstamp .. "|1"
        local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(plaintext))
        local ok, err = cookie:set({
            key = "dcap", value = ciphertext, path = "/",
            domain = ngx.var.host, httponly = true,
            max_age = 21600,
            samesite = "Strict"
            })
        if not ok then
            ngx.log(ngx.ERR, err)
            return
        end
	ngx.header.content_type = 'text/html'
        ngx.say("<head> \
  		<meta http-equiv=\"refresh\" content=\"1\"> \
		</head><a href=\"/\">One moment...</p>")
        ngx.flush()
        ngx.exit(200)
    end
end

-- captcha generator functions
require "caphtml_d"

local field, err = cookie:get("dcap")
if not field or field == nil then
    displaycap()
    ngx.flush()
    ngx.exit(200)
end

-- check if cookie is blacklisted by rate limiter. if it is show the client a message and exit. can get creative with this.
local blocked_cookies = ngx.shared.blocked_cookies
local bct, btcflags = blocked_cookies:get(field)
if bct then
    ngx.log(ngx.ERR, "Cookie " .. field .. " blacklisted.")
    ngx.header.content_type = 'text/plain'
    ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
    ngx.flush()
    ngx.exit(200)  
end

if ngx.var.request_method == "POST" then
    local field, err = cookie:get("dcap")
    if err then
        ngx.exit(403)   
    end

    if field then
        plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not plaintext then
            ngx.header.content_type = 'text/plain'
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)
        end
        cookdata = split(plaintext,"|")
        local expired = nil
        if (tonumber(cookdata[2]) + session_timeout) < ngx.now() then
            expired = true
            caperror = "Session expired"
            displaycap()
            ngx.flush()
            ngx.exit(200)
         end
	 if cookdata[1] == "captcha_solved" and not expired then
            return
         end
    end

-- resty has a library for parsing POST data but it's not really needed
    ngx.req.read_body()
    local dataraw = ngx.req.get_body_data()
    if dataraw == nil then
        caperror = "You didn't submit anything. Try again."
        displaycap()
        ngx.flush()
        ngx.exit(200)
    end

    local data = ngx.req.get_body_data()
    data = split(data, "&")
    local sentcap = ""
    for index, value in ipairs(data) do
        sentcap = sentcap .. split(value,"=")[2]
    end

    if field then
        plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not plaintext then
            ngx.header.content_type = 'text/plain'
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)
        end
        cookdata = split(plaintext,"|")

        if (tonumber(cookdata[2]) + 60) < ngx.now() then
            caperror = "Captcha expired"
            displaycap()
            ngx.flush()
            ngx.exit(200)
        end

        if sentcap == cookdata[3] then
            local newcookdata = ""
            cookdata[1] = "captcha_solved"
            for k,v in pairs(cookdata) do
                newcookdata = newcookdata .. "|" .. v
            end
            local tstamp = ngx.now()
            local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(newcookdata))
            local ok, err = cookie:set({
                key = "dcap", value = ciphertext, path = "/",
                domain = ngx.var.host, httponly = true,
                max_age = 21600,
                samesite = "Strict"
                })
            if not ok then
                ngx.say("cookie error")
                return
            end            
	    local redirect_to = ngx.var.uri
            if ngx.var.query_string ~= nil then
                redirect_to = redirect_to .. "?" .. ngx.var.query_string
            end
            return ngx.redirect(redirect_to)
        else
            caperror = "You Got That Wrong. Try again"
        end
        
    else
        caperror = "Session invalid or expired"
        displaycap()
        ngx.flush()
        ngx.exit(200)        
    end
end

plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
if not plaintext then
    ngx.header.content_type = 'text/plain'
    ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
    ngx.flush()
    ngx.exit(200)
end
cookdata = split(plaintext,"|")

if not cookdata then
    displaycap()
    ngx.flush()
    ngx.exit(200)
end

local expired = nil
if (tonumber(cookdata[2]) + session_timeout) < ngx.now() then
   expired = true
   caperror = "Session expired"
end

if cookdata[1] ~= "captcha_solved" or expired then
    displaycap()
    ngx.flush()
    ngx.exit(200)
end

