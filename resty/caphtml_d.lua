local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function base64_encode(data)
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

function base64_decode(data)
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

function in_array(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
end

local gd = require("gd")

function displaycap()
    math.randomseed(ngx.now())

    local img_width = 150;
    local img_height = 150;

    local capgrid = {}

    local checkmin = 1
    local checkmax = 6
    local checktotal = 0

    local sessiondice = "";

    while checktotal < checkmin do
        for i=1,9,1 do
             check = math.random(0,1)
             if checktotal < checkmax and check == 1 then capgrid[i] = check else capgrid[i] = 0 end             
             if check == 1 then 
                 checktotal = checktotal + 1
                 sessiondice = sessiondice .. tostring(i)
             end
        end
    end

    local cookie, err = cook:new()
    if not cookie then
        ngx.log(ngx.ERR, err)
        ngx.say("cookie error")
        ngx.exit(200)
    end

    local tstamp = ngx.now()
    local newcookdata = "cap_not_solved|" .. tstamp .. "|"
    newcookdata = newcookdata .. sessiondice

    local ciphertext = tohex(aes_128_cbc_sha512x1:encrypt(newcookdata))
    local ok, err = cookie:set({
        key = "dcap", value = ciphertext, path = "/",
        domain = ngx.var.host, httponly = true,
        max_age = 21600,
        samesite = "Strict"
        })
    if not ok then
        ngx.say("cookie error")
        ngx.exit(200)
    end

    local symbols_zero = {'○','□','♘','♢','▽','△','♖','✧','♔','♘','♕','♗','♙','♧'};
    local symbols_one = {'●','■','♞','♦','▼','▲','♜','✦','♚','♞','♛','♝','♟','♣'};

    
    local img = gd.createFromJpeg("/tmp/background-" .. math.random(0,25) .. ".jpg")
 
    if img == nil then
        img = gd.createTrueColor(150, 150)
        local white = img:colorAllocate(255, 255, 255)
        img:filledRectangle(0, 0, img_width, img_height, white)
    end

    img:setThickness(1)

    -- if 0 each row will be horizontal
    local draw_angle = 0

    local current_row = 1
    local capstring = ""
    for i=1,9,1 do
       local symbol_id = math.random(1,14)
       local fillcolor = img:colorAllocate(math.random(5,255), math.random(5,255), math.random(5,255))
       if capgrid[i] == 1 then
           capstring = capstring .. symbols_one[symbol_id]
       else
           capstring = capstring .. symbols_zero[symbol_id]
       end
       capstring = capstring .. " "
       if i % 3 == 0 then
           if draw_angle == 1 then
               angle = math.rad(math.random(0,10))
           else
               angle = 0
           end
           if current_row == 1 then
               img:stringFT(fillcolor, "/etc/nginx/font.ttf", math.random(18,22), angle, math.random(10,50), math.random(30,60), capstring)
           elseif current_row == 2 then
               img:stringFT(fillcolor, "/etc/nginx/font.ttf", math.random(18,22), angle, math.random(10,50), math.random(60,90), capstring)
           else
               img:stringFT(fillcolor, "/etc/nginx/font.ttf", math.random(18,22), angle, math.random(10,50), math.random(100,130), capstring)
           end
       current_row = current_row + 1
       capstring = ""
       end
    end
    imgbase64 = base64_encode(img:pngStrEx(6))


ngx.header.content_type = 'text/html';
ngx.say("<html lang=en> \
<head> \
<title>DDOS Protection</title> \
<meta charset=\"UTF-8\"> \
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> \
<link id=\"favicon\" rel=\"shortcut icon\" href=\"data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAABMLAAATCwAAAAAAAAAAAACtRI7/rUSO/61Ejv+tRI7/rUSO/61Fjv+qPor/pzaG/6k7if+sQo3/qDiH/6g4h/+sQ43/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Fjv+sQo3/uV6e/8iBs/+9aaT/sEyT/8V7r//Feq//sEqS/6xDjf+tRI7/rUSO/61Ejv+tRI7/rUSO/65Fj/+vR5D/rEGM/+fI3v///////fv8/+/a6f/+/f7/+vT4/7Zam/+rP4v/rkWP/61Ejv+tRI7/rUSO/61Fjv+sQYz/qTqI/6g4h//hudX/5sXc/+7Z6P////////7///ft9P+2WZr/q0CL/61Fj/+tRI7/rUSO/61Fj/+rQIv/uFyd/82Ou//Njrv/uWGf/6g6iP+uR5D/5sbc///////47vX/tlma/6s/i/+tRY//rUSO/61Ejv+uRo//qDqI/9aix///////69Hj/61Ejv+vSJD/qTqI/8BvqP//////+O/1/7ZZmv+rP4v/rUWP/61Ejv+tRI7/rkaP/6k8if/fttP//////9ekyP+oOIf/sEuS/6tAi/+7ZKH//vv9//nw9v+2WJr/qz+L/61Fj/+tRI7/rUSO/65Gj/+oOoj/1qHG///////pzeH/qj6K/6o8if+lMoP/0pjB///////47vX/tlma/6s/i/+tRY//rUSO/61Ejv+uRo//qj2K/7xmo//8+Pv//////+G61f+8ZqP/zpC8//v2+v//////+O/1/7ZZmv+rP4v/rUWP/61Ejv+tRI7/rUSO/65Gj/+pPIn/zo+7//79/v///////////////////v////////jw9v+2WZr/qz+L/61Fj/+tRI7/rUSO/61Ejv+tRI7/rUWP/6o9iv/Ab6j/37bT/+vR4//kwdr/16XI//36/P/58ff/tlma/6s/i/+tRY//rUSO/61Ejv+tRI7/rUSO/61Ejv+uRo//qj2K/6o9if+tRY7/qDmH/7VYmv/9+fv/+fH3/7ZYmv+rP4v/rUWP/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/65Gj/+uRo//rkaP/6s/i/+6Y6H//Pf6//ju9f+1WJr/q0CL/61Fj/+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/65Gj/+qPor/umOh//79/v/69Pj/tlqb/6s/i/+uRY//rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rEKN/7FNk//GfLD/xHmu/7BKkv+sQ43/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+tRI7/rUSO/61Ejv+sQo3/qDiH/6g4h/+sQ43/rUSO/61Ejv+tRI7/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==\"> \
</head><body><style>")

local file = io.open("/etc/nginx/cap_d.css")

if not file then
    ngx.exit(500)
end

local css, err = file:read("*a")

file:close()

ngx.say(css)

ngx.say("</style> \
<div class=\"container\"> \
<div class=\"inner\"> \
<div class=\"logo\"> \
<div class=\"square\" style=\"background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAMAAAAM7l6QAAAA4VBMVEX///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////9pPP/NAAAASnRSTlMABAcJCwwQFBYdHyIjKTQ2Oj5ESkxOUVZXWGBkZWlqb3Bzd3+Ag5GZnJ6io6Sxt7q+wMbHyMnNztXW2dvh5ejp6uvw8/T2+fr7/f+3i2wAAADLSURBVCjPzdPXDoJAEAVQ7NgL9q7YG/Zesc//f5DuJG4YBBLfvG93T2CyuyAIXwkAy0AwiR95Zs3Tf2SfIYs5uV57p9Iw4OAQaAiXASxYBitOghU79rjwaEvRRPf5xVXsaw8Wz0rH9gmrR/dngyrlGNYif1mWcgEHi5y9lPGUNppt7gi3WFtqeEsYz+Ro4+o6E07jrAjnMJ0dPLGqcO7ojiWUkqR45vN4CQzvuz92ssFNMOYe3OfK4gambP45/Mz6nyh/UK8XHhjh4gvTGmQQRyXgEgAAAABJRU5ErkJggg==)\"></div> \
<div class=\"text\">dread</div> \
</div>")
if caperror ~= nil
then
ngx.say("<p class=\"alert alert-danger text-center\"><strong>Error: </strong>" .. caperror .. "</p>")
else
ngx.say("<p>Due to on-going DDOS attacks against our servers, you must complete a captcha challenge to prove you are human.</p>")
end

ngx.say("<form class=\"ddos_form\" method=\"post\"> \
<div class=\"captchav2\" style=\"margin-bottom:15px;\"> \
<div class=\"imgWrap\" style=\"border:1px solid #000;background-image:url(data:image/png;base64," .. imgbase64 .. "\"></div>")
ngx.say("<div class=\"inputWrap\"> \
<input type=\"checkbox\" name=\"cap\" value=\"1\"> \
<input type=\"checkbox\" name=\"cap\" value=\"2\"> \
<input type=\"checkbox\" name=\"cap\" value=\"3\"> \
<input type=\"checkbox\" name=\"cap\" value=\"4\"> \
<input type=\"checkbox\" name=\"cap\" value=\"5\"> \
<input type=\"checkbox\" name=\"cap\" value=\"6\"> \
<input type=\"checkbox\" name=\"cap\" value=\"7\"> \
<input type=\"checkbox\" name=\"cap\" value=\"8\"> \
<input type=\"checkbox\" name=\"cap\" value=\"9\">")
ngx.say("<div class=\"c1\"></div> \
<div class=\"c2\"></div> \
<div class=\"c3\"></div> \
<div class=\"c4\"></div> \
<div class=\"c5\"></div> \
<div class=\"c6\"></div> \
<div class=\"c7\"></div> \
<div class=\"c8\"></div> \
<div class=\"c9\"></div>")
ngx.say("</div> \
</div> \
<button type=\"submit\">Verify</button> \
</form> \
</div> \
</div> \
</body> \
</html>")

end
