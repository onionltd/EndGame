local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function base64_decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function displaycap()
    ngx.header.content_type = "text/html"
    local cookie, err = cook:new()
    if not cookie then
        ngx.log(ngx.ERR, err)
        ngx.say("cookie error")
        ngx.exit(200)
    end

    local field, err = cookie:get("dcap")
    plaintext = aes_128_cbc_sha512x1:decrypt(fromhex(field))
    local blocked_cookies = ngx.shared.blocked_cookies
    blocked_cookies:set(field, 1, 3600)
    cookdata = split(plaintext, "|")
    if (cookdata[1] == "cap_not_solved") then
        if (cookdata[5] == "3") then
            ngx.say("You failed the captcha too many times. Get a new identity and try again.")
            ngx.exit(200)
        end
    end

    hour = random.number(0, 11)
    minute = random.number(0, 59)
    shour = tostring(hour)
    sminute = tostring(minute)
    if string.len(shour) < 2 then
        shour = "0" .. shour
    end
    if string.len(sminute) < 2 then
        sminute = "0" .. sminute
    end

    local gd = require("gd")

    local pickedtime = shour .. ":" .. sminute
    local radios = {}
    local ctimeindex = random.number(1, 10)
    radios[ctimeindex] = {}
    radios[ctimeindex][1] = pickedtime
    radios[ctimeindex][2] = shour .. sminute
    for i = 1, ctimeindex - 1, 1 do
        fshour = tostring(random.number(0, 11))
        fsminute = tostring(random.number(0, 59))
        if string.len(fshour) < 2 then
            fshour = "0" .. fshour
        end
        if string.len(fsminute) < 2 then
            fsminute = "0" .. fsminute
        end
        local fpickedtime = fshour .. ":" .. fsminute
        radios[i] = {}
        radios[i][1] = fpickedtime
        radios[i][2] = fshour .. fsminute
    end
    for i = ctimeindex + 1, 10, 1 do
        fshour = tostring(random.number(0, 11))
        fsminute = tostring(random.number(0, 59))
        if string.len(fshour) < 2 then
            fshour = "0" .. fshour
        end
        if string.len(fsminute) < 2 then
            fsminute = "0" .. fsminute
        end
        local fpickedtime = fshour .. ":" .. fsminute
        radios[i] = {}
        radios[i][1] = fpickedtime
        radios[i][2] = fshour .. fsminute
    end

    local function createClock(size, hours, minutes)
        local im = gd.createTrueColor(size, size)

        local white = im:colorAllocate(random.number(200, 255), random.number(200, 255), random.number(200, 255))
        local gray = im:colorAllocate(random.number(100, 150), random.number(100, 150), random.number(100, 150))
        local black = im:colorAllocate(random.number(0, 10), random.number(0, 10), random.number(0, 10))

        local hrhand = im:colorAllocate(random.number(0, 350), random.number(0, 150), random.number(0, 148))
        local minhand = im:colorAllocate(random.number(0, 350), random.number(0, 150), random.number(0, 148))

        local cxy = size / 2

        im:filledRectangle(0, 0, size, size, white)
        im:setThickness(2)
        im:arc(cxy, cxy, size, size, 0, 360, black)

        local ang = 0
        local rang, gsize
        while ang < 360 do
            rang = math.rad(ang)
            if (ang % 90) == 0 then
                gsize = 0.75
            elseif (ang % 5) == 0 then
                gsize = 0.85
            else
                gsize = 0.90
            end
            im:line(
                cxy + gsize * cxy * math.sin(rang),
                size - (cxy + gsize * cxy * math.cos(rang)),
                cxy + cxy * 0.9 * math.sin(rang),
                size - (cxy + cxy * 0.9 * math.cos(rang)),
                gray
            )
            ang = ang + 6
        end

        im:setThickness(math.max(1, size / 50))
        im:line(
            cxy,
            cxy,
            cxy + 0.45 * size * math.sin(math.rad(6 * minutes)),
            size - (cxy + 0.45 * size * math.cos(math.rad(6 * minutes))),
            hrhand
        )

        im:setThickness(math.max(1, size / 25))
        rang = math.rad(30 * hours + minutes / 2)
        im:line(cxy, cxy, cxy + 0.25 * size * math.sin(rang), size - (cxy + 0.25 * size * math.cos(rang)), minhand)

        im:setThickness(1)
        local sp = math.max(1, size / 20)
        im:filledArc(cxy, cxy, sp, sp, 0, 360, black, gd.ARC)

        im:setThickness(random.number(2, 3))
        fillcolor = im:colorAllocate(random.number(5, 255), random.number(5, 255), random.number(5, 255))
        x = random.number(40, 120)
        y = random.number(40, 120)
        im:arc(x, y, random.number(30, 90), random.number(30, 90), 0, 360, fillcolor)

        fillcolor = im:colorAllocate(random.number(5, 255), random.number(5, 255), random.number(5, 255))
        x = random.number(40, 120)
        y = random.number(40, 120)
        im:rectangle(x, y, x + random.number(30, 90), y + random.number(30, 90), fillcolor)

        x = random.number(40, 100)
        y = random.number(x + 40, 180)
        fillcolor = im:colorAllocate(random.number(5, 255), random.number(5, 255), random.number(5, 255))
        im:polygon(
            {
                {cxy, cxy},
                {random.number(10, 150), random.number(10, 150)},
                {random.number(10, 150), random.number(10, 150)}
            },
            fillcolor
        )
        return im
    end

    local im = createClock(190, hour, minute)
    local imageraw = im:jpegStr(80)
    local imageb64 = base64_encode(imageraw)

    hour = tostring(hour)
    minute = tostring(minute)
    if string.len(hour) < 2 then
        hour = "0" .. hour
    end
    if string.len(minute) < 2 then
        minute = "0" .. minute
    end

    if (cookdata[1] == "queue") then
        local tstamp = ngx.now()
        local newcookdata = "cap_not_solved|" .. tstamp .. "|" .. hour .. minute

        newcookdata = newcookdata .. "|" .. random.token(random.number(10, 20)) .. "|1"

        local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(newcookdata))
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
            ngx.say("cookie error")
            ngx.exit(200)
        end
    else
        local tstamp = ngx.now()
        local tries = tonumber(cookdata[5] + 1)
        local newcookdata = "cap_not_solved|" .. tstamp .. "|" .. hour .. minute

        newcookdata = newcookdata .. "|" .. random.token(random.number(10, 20)) .. "|" .. tries

        local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(newcookdata))
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
            ngx.say("cookie error")
            ngx.exit(200)
        end
    end

    ngx.say('<!DOCTYPE html> \
<html lang=en> \
<head> \
<title>DDOS Protection</title> \
<meta charset="UTF-8"> \
<meta name="viewport" content="width=device-width, initial-scale=1.0"> \
<link id="favicon" rel="shortcut icon" href="data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAABMLAAATCwAAAAAAAAAAAACtRI7/rUSO/61Ejv+tRI7/rUSO/61Fjv+qPor/pzaG/6k7if+sQo3/qDiH/6g4h/+sQ43/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Fjv+sQo3/uV6e/8iBs/+9aaT/sEyT/8V7r//Feq//sEqS/6xDjf+tRI7/rUSO/61Ejv+tRI7/rUSO/65Fj/+vR5D/rEGM/+fI3v///////fv8/+/a6f/+/f7/+vT4/7Zam/+rP4v/rkWP/61Ejv+tRI7/rUSO/61Fjv+sQYz/qTqI/6g4h//hudX/5sXc/+7Z6P////////7///ft9P+2WZr/q0CL/61Fj/+tRI7/rUSO/61Fj/+rQIv/uFyd/82Ou//Njrv/uWGf/6g6iP+uR5D/5sbc///////47vX/tlma/6s/i/+tRY//rUSO/61Ejv+uRo//qDqI/9aix///////69Hj/61Ejv+vSJD/qTqI/8BvqP//////+O/1/7ZZmv+rP4v/rUWP/61Ejv+tRI7/rkaP/6k8if/fttP//////9ekyP+oOIf/sEuS/6tAi/+7ZKH//vv9//nw9v+2WJr/qz+L/61Fj/+tRI7/rUSO/65Gj/+oOoj/1qHG///////pzeH/qj6K/6o8if+lMoP/0pjB///////47vX/tlma/6s/i/+tRY//rUSO/61Ejv+uRo//qj2K/7xmo//8+Pv//////+G61f+8ZqP/zpC8//v2+v//////+O/1/7ZZmv+rP4v/rUWP/61Ejv+tRI7/rUSO/65Gj/+pPIn/zo+7//79/v///////////////////v////////jw9v+2WZr/qz+L/61Fj/+tRI7/rUSO/61Ejv+tRI7/rUWP/6o9iv/Ab6j/37bT/+vR4//kwdr/16XI//36/P/58ff/tlma/6s/i/+tRY//rUSO/61Ejv+tRI7/rUSO/61Ejv+uRo//qj2K/6o9if+tRY7/qDmH/7VYmv/9+fv/+fH3/7ZYmv+rP4v/rUWP/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/65Gj/+uRo//rkaP/6s/i/+6Y6H//Pf6//ju9f+1WJr/q0CL/61Fj/+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/65Gj/+qPor/umOh//79/v/69Pj/tlqb/6s/i/+uRY//rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rEKN/7FNk//GfLD/xHmu/7BKkv+sQ43/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+sQo3/qDiH/6g4h/+sQ43/rUSO/61Ejv+tRI7/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="> \
</head><body><style>')

    local file = io.open("/etc/nginx/cap_d.css")

    if not file then
        ngx.exit(500)
    end

    local css, err = file:read("*a")

    file:close()

    ngx.say(css)

    ngx.say('</style> \
<div class="container"> \
<div class="inner"> \
<div class="logo"> \
<div class="square" style="background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAMAAAAM7l6QAAAA4VBMVEX///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////9pPP/NAAAASnRSTlMABAcJCwwQFBYdHyIjKTQ2Oj5ESkxOUVZXWGBkZWlqb3Bzd3+Ag5GZnJ6io6Sxt7q+wMbHyMnNztXW2dvh5ejp6uvw8/T2+fr7/f+3i2wAAADLSURBVCjPzdPXDoJAEAVQ7NgL9q7YG/Zesc//f5DuJG4YBBLfvG93T2CyuyAIXwkAy0AwiR95Zs3Tf2SfIYs5uV57p9Iw4OAQaAiXASxYBitOghU79rjwaEvRRPf5xVXsaw8Wz0rH9gmrR/dngyrlGNYif1mWcgEHi5y9lPGUNppt7gi3WFtqeEsYz+Ro4+o6E07jrAjnMJ0dPLGqcO7ojiWUkqR45vN4CQzvuz92ssFNMOYe3OfK4gambP45/Mz6nyh/UK8XHhjh4gvTGmQQRyXgEgAAAABJRU5ErkJggg==)"></div> \
<div class="text">SITENAME</div> \
</div>')

    if caperror ~= nil then
        ngx.say('<p class="alert alert-danger text-center"><strong>Error: </strong>' .. caperror .. "</p>")
    else
        ngx.say("<p>Prove that you are human. Select the time shown on the clock image.</p>")
    end
    ngx.say('<form class="ddos_form" method="post"> \
<div class="captchav2" style="margin-bottom:15px;"> \
<div class="imgWrap" style="border:2px solid #fff; max-width: 100%; border-radius: 50%; background-image:url(data:image/png;base64,' .. imageb64 .. ');"></div>')
    ngx.say("</div>")
    ngx.say('<div style="margin-bottom: 15px;">')
    ngx.say('<select class="center" name="cap" required>')
    for i = 0, 11, 1 do
        if i < 10 then
            si = "0" .. tostring(i)
        else
            si = i
        end
        ngx.say('<option value="' .. si .. '">' .. si .. "</option>\n")
    end
    ngx.say("</select> : ")
    ngx.say('<select name="cap" required>')
    for i = 0, 59, 1 do
        if i < 10 then
            si = "0" .. tostring(i)
        else
            si = i
        end
        ngx.say('<option value="' .. si .. '">' .. si .. "</option>\n")
    end
    ngx.say("</select>")
    --ngx.say("<input type=\"text\" required  name=\"cap\" maxlength=\"2\" size=\"2\" placeholder=\"hh\"> : ")
    --ngx.say("<input type=\"text\" required  name=\"cap\" maxlength=\"2\" size=\"2\" placeholder=\"mm\">")
    ngx.say("</div>")
    ngx.say(
        '<div class="expire"> \
	<div class="timer"> \
		<div class="time-part-wrapper"> \
			<div class="time-part seconds tens"> \
				<div class="digit-wrapper"> \
					<span class="digit">0</span> \
					<span class="digit">5</span> \
					<span class="digit">4</span> \
					<span class="digit">3</span> \
					<span class="digit">2</span> \
					<span class="digit">1</span> \
					<span class="digit">0</span> \
				</div> \
			</div> \
			<div class="time-part seconds ones"> \
				<div class="digit-wrapper"> \
					<span class="digit">0</span> \
					<span class="digit">9</span> \
					<span class="digit">8</span> \
					<span class="digit">7</span> \
					<span class="digit">6</span> \
					<span class="digit">5</span> \
					<span class="digit">4</span> \
					<span class="digit">3</span> \
					<span class="digit">2</span> \
					<span class="digit">1</span> \
					<span class="digit">0</span> \
				</div> \
			</div> \
		</div> \
		<div class="time-part-wrapper"> \
			<div class="time-part hundredths tens"> \
				<div class="digit-wrapper"> \
					<span class="digit">0</span> \
					<span class="digit">9</span> \
					<span class="digit">8</span> \
					<span class="digit">7</span> \
					<span class="digit">6</span> \
					<span class="digit">5</span> \
					<span class="digit">4</span> \
					<span class="digit">3</span> \
					<span class="digit">2</span> \
					<span class="digit">1</span> \
					<span class="digit">0</span> \
				</div> \
			</div> \
			<div class="time-part hundredths ones"> \
				<div class="digit-wrapper"> \
					<span class="digit">0</span> \
					<span class="digit">9</span> \
					<span class="digit">8</span> \
					<span class="digit">7</span> \
					<span class="digit">6</span> \
					<span class="digit">5</span> \
					<span class="digit">4</span> \
					<span class="digit">3</span> \
					<span class="digit">2</span> \
					<span class="digit">1</span> \
					<span class="digit">0</span> \
				</div> \
			</div> \
		</div> \
	</div> \
</div>')

    ngx.say('<button class="before" type="submit">Verify</button> \
<button class="expired" type="submit"> Refresh (expired)</button> \
</form> \
</div> \
</div> \
</body> \
</html>')
end

