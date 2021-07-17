-- encryption key and salt must be shared across fronts. salt must be 8 chars
local key = "encryption_key"
local salt = "salt1234"
-- for how long the captcha is valid. 120 sec is for testing, 3600 1 hour should be production.
local session_timeout = sessionconfigvalue

aes = require "resty.aes"
str = require "resty.string"
cook = require "resty.cookie"
random = require "resty.random"

aes_128_cbc_sha512x1 = aes:new(key, salt, aes.cipher(128, "cbc"), aes.hash.sha512, 1)

local cookie, err = cook:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    return
end

function fromhex(str)
    return (str:gsub(
        "..",
        function(cc)
            return string.char(tonumber(cc, 16))
        end
    ))
end

function tohex(str)
    return (str:gsub(
        ".",
        function(c)
            return string.format("%02X", string.byte(c))
        end
    ))
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

-- only GET and POST requests are allowed the others are not used.
if ngx.var.request_method ~= "POST" and ngx.var.request_method ~= "GET" then
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

-- check if cookie is blacklisted by rate limiter. if it is show the client a message and exit. can get creative with this.
local field, err = cookie:get("dcap")
local blocked_cookies = ngx.shared.blocked_cookies
local bct, btcflags = blocked_cookies:get(field)
if bct then
    ngx.header.content_type = "text/plain"
    ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
    ngx.flush()
    ngx.exit(200)
end

-- check cookie support similar to testcookie
if ngx.var.request_method == "GET" then
    local field, err = cookie:get("dcap")
    if err or not field then
        local tstamp = ngx.now() + 5
        local plaintext = "queue|" .. tstamp .. "|1|" .. random.token(random.number(10, 20))
        local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(plaintext))
        local ok, err =
            cookie:set(
            {
                key = "dcap",
                value = ciphertext,
                path = "/",
                domain = ngx.var.host,
                httponly = true,
                max_age = 120,
                samesite = "Lax"
            }
        )
        if not ok then
            ngx.log(ngx.ERR, err)
            return
        end
        ngx.header.content_type = "text/html"
        local file = io.open("/etc/nginx/queue.html")
        if not file then
            ngx.exit(500)
        end
        local queue, err = file:read("*a")
        file:close()
        ngx.say(queue)
        ngx.flush()
        ngx.exit(200)
    else
        plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not plaintext then
            ngx.header.content_type = "text/plain"
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)
        end
        cookdata = split(plaintext, "|")
        local expired = nil
        if (cookdata[1] == "queue") then
            if (tonumber(cookdata[2])) > ngx.now() or (tonumber(cookdata[2])) > ngx.now() + 15 then
                if pa ~= "no_proxy" then
                    local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
                    if not ok then
                        ngx.log(ngx.ERR, "failed to create timer: ", err)
                        return
                    end
                end
                local blocked_cookies = ngx.shared.blocked_cookies
                blocked_cookies:set(field, 1, 3600)
                ngx.exit(444)
            end

            -- captcha generator functions
            require "caphtml_d"

            local expired = nil

            displaycap(session_timeout)
            ngx.flush()
            ngx.exit(200)
        elseif (cookdata[1] == "cap_not_solved") then
            if (tonumber(cookdata[2]) + 60) > ngx.now() then
                if pa ~= "no_proxy" then
                    local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
                    if not ok then
                        ngx.log(ngx.ERR, "failed to create timer: ", err)
                        return
                    end
                end
                ngx.header.content_type = "text/html"
                ngx.say("<h1>THINK OF WHAT YOU HAVE DONE!</h1>")
                ngx.say("<p>That captcha was generated just for you. And look at what you did. Ignoring the captcha... not even giving an incorrect answer to his meaningless existence. You couldn't even give him false hope. Shame on you.</p>")
                ngx.say("<p>Don't immedately refresh for a new captcha! Try and fail. You must now wait about a minute for a new captcha to load.</p>")
                ngx.flush()
                ngx.exit(200)
            end
            local expired = nil
            require "caphtml_d"
            displaycap(session_timeout)
            ngx.flush()
            ngx.exit(200)
        elseif (cookdata[1] == "captcha_solved") then
            if (tonumber(cookdata[2]) + session_timeout) < ngx.now() then
                require "caphtml_d"
                local expired = true
                caperror = "Session expired"
                displaycap(session_timeout)
                ngx.flush()
                ngx.exit(200)
            end
        else
            local ok, err = ngx.timer.at(0, kill_circuit, ngx.var.remote_addr, ngx.var.proxy_protocol_addr)
            if not ok then
                ngx.log(ngx.ERR, "failed to create timer: ", err)
                return
            end
            local blocked_cookies = ngx.shared.blocked_cookies
            blocked_cookies:set(field, 1, 3600)
            ngx.header.content_type = "text/plain"
            ngx.say("That isn't going to work here")
            ngx.flush()
            ngx.exit(200)
        end
    end
end

if ngx.var.request_method == "POST" then
    local field, err = cookie:get("dcap")
    if err then
        ngx.exit(403)
    end

    if field then
        plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not plaintext then
            ngx.header.content_type = "text/plain"
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)
        end
        cookdata = split(plaintext, "|")
        local expired = nil
        if (cookdata[1] == "cap_not_solved") then
            if (tonumber(cookdata[2]) + session_timeout) < ngx.now() then
                expired = true
                require "caphtml_d"
                caperror = "Session expired"
                displaycap(session_timeout)
                ngx.flush()
                ngx.exit(200)
            end
        elseif (cookdata[1] == "captcha_solved") then
            return
        end
    end

    require "caphtml_d"

    -- resty has a library for parsing POST data but it's not really needed
    ngx.req.read_body()
    local dataraw = ngx.req.get_body_data()
    if dataraw == nil then
        caperror = "You didn't submit anything. Try again."
        displaycap(session_timeout)
        ngx.flush()
        ngx.exit(200)
    end

    local data = ngx.req.get_body_data()
    data = split(data, "&")
    local sentcap = ""
    for index, value in ipairs(data) do
        sentcap = sentcap .. split(value, "=")[2]
    end

    if field then
        plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
        if not plaintext then
            ngx.header.content_type = "text/plain"
            ngx.say("403 DDOS fliter killed your path. (You probably sent too many requests at once). Not calling you a bot, bot, but grab a new identity and try again.")
            ngx.flush()
            ngx.exit(200)
        end
        cookdata = split(plaintext, "|")

        if (tonumber(cookdata[2]) + 60) < ngx.now() then
            caperror = "Captcha expired"
            displaycap(session_timeout)
            ngx.flush()
            ngx.exit(200)
        end

        if string.lower(sentcap) == string.lower(cookdata[3]) then
            local newcookdata = ""
            cookdata[1] = "captcha_solved"
            cookdata[2] = ngx.now()
            for k, v in pairs(cookdata) do
                newcookdata = newcookdata .. "|" .. v
            end
            newcookdata = newcookdata .. "|" .. random.token(random.number(10, 20))
            local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(newcookdata))
            local ok, err =
                cookie:set(
                {
                    key = "dcap",
                    value = ciphertext,
                    path = "/",
                    domain = ngx.var.host,
                    httponly = true,
                    max_age = session_timeout,
                    samesite = "Lax"
                }
            )
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
        displaycap(session_timeout)
        ngx.flush()
        ngx.exit(200)
    end
end
