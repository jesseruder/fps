require "constants"
Engine = require "engine"

function resetGame()
   
end

function love.load()
    -- window graphics settings
    --GraphicsWidth, GraphicsHeight = 520*2, (520*9/16)*2
    GraphicsWidth = love.graphics.getWidth()
    GraphicsHeight = love.graphics.getHeight()
    InterfaceWidth, InterfaceHeight = GraphicsWidth, GraphicsHeight
    OffsetX = 0
    OffsetY = 0
    TimeElapsed = 0.0
    love.graphics.setBackgroundColor(0,0.7,0.95)
    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("rough")
    -- love.window.setMode(GraphicsWidth,GraphicsHeight, {vsync = -1, msaa = 8})

    love.graphics.setCanvas()
    DX = 0
    DY = 0

    Scene = Engine.newScene(GraphicsWidth, GraphicsHeight)

    rectColor({
        {-1, -1, 1,   1,0},
        {-1, 1, 1,    1,1},
        {1, 1, 1,     0,1},
        {1, -1, 1,    0,0}
    }, {1,0,0}, 1.0)

end

--[[
1     2

4     3
]]--
function rect(coords, texture, scale, fogAmount)
    local model = Engine.newModel({ coords[1], coords[2], coords[4], coords[2], coords[3], coords[4] }, texture, nil, nil, nil, scale, fogAmount)
    table.insert(Scene.modelList, model)
    return model
end
function modelFromCoords(coords, texture, scale, fogAmount)
    local model = Engine.newModel(coords, texture, nil, nil, nil, scale, fogAmount)
    table.insert(Scene.modelList, model)
    return model
end

function modelFromCoordsColor(coords, color, scale, fogAmount)
    local model = Engine.newModel(coords, nil, nil, color, { 
        {"VertexPosition", "float", 3}, 
    }, scale)
    table.insert(Scene.modelList, model)
    return model
end
function addRectVerts(obj, coords)
    table.insert(obj, coords[1])
    table.insert(obj, coords[2])
    table.insert(obj, coords[4])
    table.insert(obj, coords[2])
    table.insert(obj, coords[3])
    table.insert(obj, coords[4])
end

function rectColor(coords, color, scale)
    local model = Engine.newModel({ coords[1], coords[2], coords[4], coords[2], coords[3], coords[4] }, nil, nil, color, { 
        {"VertexPosition", "float", 3}, 
    }, scale)
    table.insert(Scene.modelList, model)
    return model
end

function triColor(coords, color, scale)
    local model = Engine.newModel({ coords[1], coords[2], coords[3] }, nil, nil, color, { 
        {"VertexPosition", "float", 3}, 
    }, scale)
    table.insert(Scene.modelList, model)
    return model
end

function updateVelocity()
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        DX = 0
        DY = 1
    elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        DX = 0
        DY = -1
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        DX = -1
        DY = 0
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        DX = 1
        DY = 0
    else
        DX = 0
        DY = 0
    end
end

function love.keyreleased(key)
    updateVelocity()
end

function love.keypressed(key)
    if love.keyboard.isDown("c") then
        local isRelative = love.mouse.getRelativeMode()
        love.mouse.setRelativeMode(not isRelative)
    end

    updateVelocity()

    --local turnDirection = love.keyboard.isDown("left") and -1 or (love.keyboard.isDown("right") and 1 or 0)
end

function love.update(dt)
    TimeElapsed = TimeElapsed + dt
    -- Scene:basicCamera(dt)
    
    LogicAccumulator = LogicAccumulator+dt

    -- update 3d scene
    PhysicsStep = false
    if LogicAccumulator >= 1/LogicRate then
        dt = 1/LogicRate
        LogicAccumulator = LogicAccumulator - 1/LogicRate
        PhysicsStep = true
    else
        return
    end

    local Camera = Engine.camera
    local angle = Camera.angle.x

    Camera.pos.x = Camera.pos.x + (math.cos(angle) * DX + math.cos(angle - math.pi/2) * DY) * dt
    Camera.pos.z = Camera.pos.z + (math.sin(angle) * DX + math.sin(angle - math.pi/2) * DY) * dt
end

function love.draw()
    Scene:render(true, TimeElapsed)

    -- draw HUD
    Scene:renderFunction(
        function ()
            love.graphics.setColor(FontColor[1], FontColor[2], FontColor[3], 1)
            love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 20)
            love.graphics.print("[c] to capture or release mouse input", GraphicsWidth - 350, 20)
            
            love.graphics.setColor(1, 1, 1, 1)
        end, true
    )
end

function love.mousemoved(x,y, dx,dy)
    -- forward mouselook to Scene object for first person camera control
    Scene:mouseLook(x,y, dx,dy)
end
