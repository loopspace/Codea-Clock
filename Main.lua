-- DodecaClock

supportedOrientations(LANDSCAPE_ANY)
function setup()
    displayMode(OVERLAY)
    displayMode(FULLSCREEN)
    cmodule "Shape Clock"
    cmodule.path("Base", "Maths", "Graphics", "Utilities")
    cimport "MeshExt"
    cimport "VecExt"
    cimport "ColourExt"
    touches = cimport "Touch"()
    view = cimport "View"(nil,touches)
    view.useGravity = false
    view.currentGravity = vec4(1,0,0,0)
    seconds = Clock(12)
    minutes = Clock(12)
    hours = Clock(4)
    --[[
    s = mesh()
    s.shader = lighting()
    s.shader.light = vec3(0,0,1):normalise()
    s.shader.ambient = 0.5
    s:addSphere()
      ]]
    img = image(WIDTH,HEIGHT)
end

function draw()
    local ctx
    if isRecording() then
        setContext(img,true)
        ctx = true
    end
    background(40,40,50)
    touches:draw()
    --[[
    pushMatrix()
    scale(.5)
    sprite(img,WIDTH/2,60)
    popMatrix()
    --]]
    view:draw()

    --[[
    perspective()
    camera(0,0,10,0,0,0,0,1,0)
      ]]
    local time = getTime()--{hour = 12, min = 58, sec = 50})
    scale(1.3)
    pushMatrix()

    translate(4,0,0)
    seconds:draw(time.sec+time.msec)
    popMatrix()
    pushMatrix()
    translate(0,0,0)
    local mmin
    if time.sec == 59 then
        mmin = time.msec
    else
        mmin = 0
    end

    minutes:draw(time.min+mmin)
    popMatrix()
    pushMatrix()
    translate(-4,0,0)
    local mhr
    if time.sec == 59 and time.min == 59 then
        mhr = time.msec
    else
        mhr = 0
    end
    rotate(qRotation(math.pi/10,0,1,0))
    rotate(qRotation(math.pi/3.5,1,0,0))
    hours:draw(time.hour-1+mhr)
    -- hours:draw(time.sec+time.msec)
    popMatrix()
    --[[
    s.shader.invModel = modelMatrix():inverse():transpose()
    s:draw()
      ]]
    if ctx then
        setContext()
        resetMatrices()
        sprite(img,WIDTH/2,HEIGHT/2)
    end
end

function touched(t)
    touches:addTouch(t)
end

function click(t)
    local a = math.floor(t)
    if t < a+.6 then
        return a
    else
        return (t- a -.6)/.4 + a
    end
end

function step(t,a,b)
    t = (t-a)/(b-a)
    return math.min(1,math.max(t,0))
end

local __seconds = 0
local __offset
function getTime(t)
    local time
    if t then
        time = {}
        time.msec = ElapsedTime - math.floor(ElapsedTime)
        time.sec = t.sec + math.floor(ElapsedTime)
        time.min = t.min + math.floor(time.sec/60)
        time.hour = (t.hour + math.floor(time.min/60)-1)%12+1
        time.min = time.min%60
        time.sec = time.sec%60
    else
        time = os.date("*t")
        if time.sec ~= __seconds then
            __seconds = time.sec
            __offset = ElapsedTime
        end
        time.msec = ElapsedTime - __offset
    end
    return time
end

Clock = class()

local __initialised
local __init
local __dodeca
local __initDodeca
local __tetra
local __initTetra
local __three
local __four
local __five
local __rfive
local __twelve

local __dodecaTime = function(t,q)
    local ft = t - math.floor(t/5)*5
    local st = t - math.floor(t/60)*60
    local fv
    if math.floor(t/10)%2 == 0 then
        fv = __rfive
    else
        fv = __five
    end
    return fv(click(ft))*q*__twelve(click(st))
end

local __setDodeca = function(s)
    local phi = (1+math.sqrt(5))/2
    s.mesh = __dodeca
    s.setTime = __dodecaTime
    s.base = qRotation(9*math.pi/10,0,0,1)*vec3(-phi,0,1):rotateTo(vec3(0,0,1))
end

local __tetraTime = function(t,q)
    local ft = t - math.floor(t/3)*3
    local st = t - math.floor(t/12)*12
    return __three(click(ft))*q*__four(click(st))
end

local __setTetra = function(s)
    s.mesh = __tetra
    s.setTime = __tetraTime
    s.base = qRotation(math.pi/4,0,0,1)*vec3(-1,-1,-1):rotateTo(vec3(0,0,1))
end

function Clock:init(n)
    if not __initialised then
        __init()
    end
    if n == 12 then
        __setDodeca(self)
    else
        __setTetra(self)
    end
end

function Clock:draw(t)
    pushMatrix()
    self:rotate(t)
    self.mesh.shader.invModel = modelMatrix():inverse():transpose()
    self.mesh:draw()
    popMatrix()
end

function Clock:rotate(t)
    rotate(self.setTime(t,self.base))
end

local __digits = {
0,4,3,2,1,      -- 0,1,2,3,4
48,47,46,45,49, -- 5,6,7,8,9
36,37,38,39,35, -- 10,11,12,13,14
51,52,53,54,50, -- 15,16,17,18,19
42,41,40,44,43, -- 20,21,22,23,24
59,55,56,57,58, -- 25,26,27,28,29
30,31,32,33,34, -- 30,31,32,33,34
18,19,15,16,17, -- 35,36,37,38,39,
6,5,9,8,7,      -- 40,41,42,43,44,
21,20,24,23,22, -- 45,46,47,48,49,
12,13,14,10,11, -- 50,51,52,53,54,
29,28,27,26,25, -- 55,56,57,58,59
}

function __init()
    __initDodeca()
    __initTetra()
    __initialised = true
end

function __initDodeca()
    local img = image(1200,100)
    setContext(img)
    local str = 1
    pushMatrix()
    pushStyle()
    translate(50,50)
    for i=1,12 do
        fill(color():new("hsl",math.floor(__digits[str]/5)/12,1,.5))
        ellipse(0,0,50)
        for j=1,5 do
            rotate(-72)
            fill(0, 0, 0, 255)
            text(__digits[str],0,-25)
            str = str + 1
        end
        translate(100,0)
    end
    popStyle()
    popMatrix()
    setContext()
    local texc = {}
    local t
    for i=1,5 do
        t = vec2(0,1):rotate(i*math.pi*2/5)
        t.x = t.x/24*.9
        t.y = t.y/2*.9
        table.insert(texc,t)
    end
    __dodeca = mesh()
    __dodeca.shader = lighting()
    __dodeca.shader.useTexture = 1
    __dodeca.texture = img
    __dodeca.shader.light = vec3(1,0,1):normalise()
    __dodeca.shader.ambient = 0.5

    local ver = {}
    for i=-1,1,2 do
        for j=-1,1,2 do
            for k=-1,1,2 do
                table.insert(ver,vec3(i,j,k))
            end
        end
    end
    local n,p,u,w,nf,o
    local phi = (1+math.sqrt(5))/2
    local f = function(u) return vec3(u.y,u.z,u.x) end
    for i=-1,1,2 do
        for j=-1,1,2 do
            n = vec3(i*phi,j/phi,0)
            for k=1,3 do
                n = f(n)
                table.insert(ver,n)
            end
        end
    end
    nf = 0
    for i=-1,1,2 do
        for j=-1,1,2 do
            n = vec3(j,phi,0)
            for k=1,3 do
                n = f(n)
                p = {}
                for k,v in ipairs(ver) do
                    if v:dot(n) == i*phi*phi then
                        table.insert(p,v)
                    end
                end
                u = (p[1] - p[1]:dot(i*n:normalise())):normalise()
                w = i*n:cross(u)
                table.sort(p, function(a,b)
                    local c = math.atan2(w:dot(a),u:dot(a))
                    local d = math.atan2(w:dot(b),u:dot(b))
                    return c < d
                end)
                __dodeca:addPolygon({
                    vertices = p,
                    texCoords = texc,
                    texOrigin = vec2((2*nf + 1)/24,1/2),
                -- texSize = vec2(24,2),
                -- colour = color():new("hsl",nf/12,1,.5),
                    colour = color(255, 255, 255, 255),
                -- viewFrom = vec3(0,0,0) --2*i*n,
                })
                nf = nf + 1
            end
        end
    end

    p = {}
    n = vec3(-phi,0,1)
    for k,v in ipairs(ver) do
        if v:dot(n) == phi*phi then
            table.insert(p,v)
        end
    end
    u = (p[1] - p[1]:dot(n:normalise())):normalise()
    w = n:cross(u)
    table.sort(p, function(a,b)
        local c = math.atan2(w:dot(a),u:dot(a))
        local d = math.atan2(w:dot(b),u:dot(b))
        return c < d
    end)
    local vertexrots = {}
    for k,v in ipairs(p) do
        table.insert(vertexrots,
            qRotation(2*math.pi/3,v)--^baserot
        )
    end
    local qas = vec4(1,0,0,0):make_slerp(vertexrots[1])
    local qbs = vec4(1,0,0,0):make_slerp(vertexrots[3]^"")
    local qa = function(t) return qas(step(t,0,1)) end
    local qb = function(t) return qbs(step(t,0,1)) end
    local qc = function(t) return qb(t-19)*qb(t-14)*qa(t-9)*qa(t-4) end
    __twelve = function(t) return qc(t-40)*qc(t-20)*qc(t) end
    __five = vec4(1,0,0,0):make_slerp(qRotation(2*math.pi/5,0,0,1))
    __rfive = vec4(1,0,0,0):make_slerp(qRotation(-2*math.pi/5,0,0,1))
end

local __tdigits = {
    2,3,1,
    5,6,4,
    7,8,9,
    12,10,11,
}

function __initTetra()
    local img = image(400,100)
    setContext(img)
    local str = 1
    pushMatrix()
    pushStyle()
    translate(50,50)
    for i=1,4 do
        fill(color():new("hsl",math.floor((__tdigits[str]-1)/3)/4,1,.5))
        ellipse(0,0,50)
        for j=1,3 do
            rotate(-120)
            fill(0, 0, 0, 255)
            text(__tdigits[str],0,-15)
            str = str + 1
        end
        translate(100,0)
    end
    popStyle()
    popMatrix()
    setContext()
    local texc = {}
    local t
    for i=1,3 do
        t = vec2(0,1):rotate(i*math.pi*2/3)
        t.x = t.x/8*.9
        t.y = t.y/2*.9
        table.insert(texc,t)
    end
    __tetra = mesh()
    __tetra.shader = lighting()
    __tetra.shader.useTexture = 1
    __tetra.texture = img
    __tetra.shader.light = vec3(1,0,1):normalise()
    __tetra.shader.ambient = 0.5

    local ver = {
        vec3(1,1,1),
        vec3(1,-1,-1),
        vec3(-1,-1,1),
        vec3(-1,1,-1),
    }
    local n,p,u,w,nf,o
    nf = 0
    for k,v in ipairs(ver) do
        n = -v
        p = {}
        for k,v in ipairs(ver) do
            if v:dot(n) == 1 then
                table.insert(p,v)
            end
        end
        u = (p[1] - p[1]:dot(n:normalise())):normalise()
        w = n:cross(u)
        table.sort(p, function(a,b)
            local c = math.atan2(w:dot(a),u:dot(a))
            local d = math.atan2(w:dot(b),u:dot(b))
            return c < d
        end)
        __tetra:addPolygon({
            vertices = p,
            texCoords = texc,
            texOrigin = vec2((2*nf + 1)/8,1/2),
            -- texSize = vec2(24,2),
            -- colour = color():new("hsl",nf/12,1,.5),
            colour = color(255, 255, 255, 255),
            -- viewFrom = vec3(0,0,0) --2*i*n,
        })
        nf = nf + 1
    end

    p = {}
    n = vec3(-1,-1,-1)
    for k,v in ipairs(ver) do
        if v:dot(n) == 1 then
            table.insert(p,v)
        end
    end
    u = (p[1] - p[1]:dot(n:normalise())):normalise()
    w = n:cross(u)
    table.sort(p, function(a,b)
        local c = math.atan2(w:dot(a),u:dot(a))
        local d = math.atan2(w:dot(b),u:dot(b))
        return c < d
    end)
    local vertexrots = {}
    for k,v in ipairs(p) do
        table.insert(vertexrots,
            qRotation(2*math.pi/3,v)
        )
    end

    local qas = vec4(1,0,0,0):make_slerp(qRotation(math.pi,vec3(1,0,0)))
    local qbs = vec4(1,0,0,0):make_slerp(qRotation(math.pi,vec3(0,1,0)))
    local qa = function(t) return qas(step(t,0,1)) end
    local qb = function(t) return qbs(step(t,0,1)) end
    local qc = function(t) return qb(t-5)*qa(t-2) end
    __four = function(t) return qc(t-6)*qc(t) end

    __three = vec4(1,0,0,0):make_slerp(qRotation(2*math.pi/3,0,0,1))
end
