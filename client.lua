require "constants"
Engine = require "engine"

require "levels_tools.skybox"
require "levels_tools.heightmap"
require "levels_tools.terrain"
require "levels_tools.walls"

require "player"

MAX_BULLETS = 200
MAX_BULLET_DIST = 15.0

MY_SPEED = 3
ENEMY_SPEED = 2
ENEMY_ROTATION_SPEED = 0.8

NUM_ENEMIES = 10
STARTING_HEALTH = 10

SCORE = 0
INITIAL_CURRENT_PLAYER_HEALTH = 100
CURRENT_PLAYER_HEALTH = INITIAL_CURRENT_PLAYER_HEALTH
PENALTY_FOR_DYING = 20

function resetGame()
    BulletsVerts = {}
    BulletsMesh = nil
    BulletsIdx = 1
    Players = {}

    CurrentPlayer = {
        angle = 0.0,
        angleY = 0.0,
        size = 0.5,
        x = CURRENT_SPAWN_X,
        y = 0.5,
        z = CURRENT_SPAWN_Z,
    }

    table.insert(Players, CurrentPlayer)

    for i = 1, NUM_ENEMIES do
        local player = createPlayer()
        table.insert(Players, player)
    end
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

    BigFont = love.graphics.newFont(20)
    HugeFont = love.graphics.newFont(100)
    DefaultFont = love.graphics.getFont()

    love.graphics.setCanvas()
    DX = 0
    DY = 0

    Scene = Engine.newScene(GraphicsWidth, GraphicsHeight)

    WorldSize = 50

    makeHeightMap()
    --[[addMountainRelative(0, 0, 6, 0.1)
    addMountainRelative(0.8, 0.8, 6, 0.1)
    addMountainRelative(0, 0.8, 6, 0.1)
    addMountainRelative(0.8, 0, 6, 0.1)

    addMountainRelative(0.9, 0.3, 2, 0.07)
    addMountainRelative(0.6, 0.75, 3, 0.08)
    addMountainRelative(0.1, 0.8, 1, 0.09)
    addMountainRelative(0.76, 0.13, 2, 0.13)

    addMountainRelative(0.5, 0.30, 3, 0.07)]]--


    local defaultSkybox = love.graphics.newImage("assets/levels/dark-skybox.png")
    local terrainImage = love.graphics.newImage("assets/concrete.png")
    skybox(defaultSkybox)
    terrain(terrainImage)

    makeWalls()

    --[[rectColor({
        {-1, -1, 1,   1,0},
        {-1, 1, 1,    1,1},
        {1, 1, 1,     0,1},
        {1, -1, 1,    0,0}
    }, {1,0,0}, 1.0)]]--

    resetGame()
end

function fireBullet(player)
    local angle = player.angle
    local angleY = player.angleY

    fireSingleBullet(player.x, player.y, player.z, angle, angleY, planeVec(angle, -0.25, 0.0), math.random() * 0.03 + 0.1, TimeElapsed + 0.1 * math.random())
    fireSingleBullet(player.x, player.y, player.z, angle, angleY, planeVec(angle, 0.25, 0.0), math.random() * 0.03 + 0.1, TimeElapsed + 0.1 * math.random())

    BulletsMesh = love.graphics.newMesh({
        {"VertexPosition", "float", 3},
        {"startTime", "float", 1}
    }, BulletsVerts, "triangles")
end

function canSeeCurrentPlayerFrom(x, z)
    local startVec = {x, z}
    local endVec = {CurrentPlayer.x, CurrentPlayer.z}

    local diffVec = {endVec[1] - startVec[1], endVec[2] - startVec[2]}
    local fullDist = math.sqrt(diffVec[1] * diffVec[1] + diffVec[2] * diffVec[2])
    diffVec[1] = diffVec[1] / fullDist
    diffVec[2] = diffVec[2] / fullDist

    local dist = 0.0
    while dist <= fullDist do
        local currentPos = {startVec[1] + diffVec[1] * dist, startVec[2] + diffVec[2] * dist}

        dist = dist + 0.25

        if isCoordWall(currentPos[1], currentPos[2]) then
            return false
        end
    end

    return true
end

function fireSingleBullet(originX, originY, originZ, angle, angleY, diff, yDiff, time)
    local bulletVecX = math.cos(angle) * math.cos(-angleY)
    local bulletVecY = math.sin(-angleY)
    local bulletVecZ = math.sin(angle) * math.cos(-angleY)

    local startVec = {originX + diff[1], originY + yDiff, originZ + diff[2]}

    local dist = 1.0
    local endVec = {}

    while dist < MAX_BULLET_DIST do
        endVec = {startVec[1] + bulletVecX * dist, startVec[2] + bulletVecY * dist, startVec[3] + bulletVecZ * dist}

        local isHit = false
        for k,v in pairs(Players) do
            if math.sqrt(math.pow(endVec[1] - v.x, 2.0) + math.pow(endVec[2] - v.y, 2.0) + math.pow(endVec[3] - v.z, 2.0)) < v.size then
                playerHit(v)
                isHit = true
                break
            end
        end

        if isHit then
            break
        end

        if isCoordWall(endVec[1], endVec[3]) or endVec[2] < 0.0 then
            Scene:smallExplosion(endVec[1], endVec[2], endVec[3])
            break
        end

        dist = dist + 0.1
    end

    local billboardVec = {0.0, 0.02, 0.0}

    table.insert(BulletsVerts, BulletsIdx, {startVec[1], startVec[2], startVec[3], time})
    table.insert(BulletsVerts, BulletsIdx + 1, {endVec[1], endVec[2], endVec[3], time})
    table.insert(BulletsVerts, BulletsIdx + 2, {endVec[1] + billboardVec[1], endVec[2] + billboardVec[2], endVec[3] + billboardVec[3], time})
    table.insert(BulletsVerts, BulletsIdx + 3, {startVec[1], startVec[2], startVec[3], time + 0.1})
    table.insert(BulletsVerts, BulletsIdx + 4, {endVec[1] + billboardVec[1], endVec[2] + billboardVec[2], endVec[3] + billboardVec[3], time + 0.1})
    table.insert(BulletsVerts, BulletsIdx + 5, {startVec[1] + billboardVec[1], startVec[2] + billboardVec[2], startVec[3] + billboardVec[3], time + 0.1})

    BulletsIdx = BulletsIdx + 6
    if BulletsIdx > MAX_BULLETS then
        BulletsIdx = 1
    end
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
    DX = 0
    DY = 0

    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        DY = DY + 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        DY = DY - 1
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        DX = DX - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        DX = DX + 1
    end

    if DX ~= 0 or DY ~= 0 then
        local l = math.sqrt(DX * DX + DY * DY)
        DX = DX / l
        DY = DY / l
    end
end

function love.mousepressed( x, y, button, istouch, presses )
    if button == 1 then
        fireBullet(CurrentPlayer)
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

function planeVec(angle, dx, dy)
    return {
        (math.cos(angle + math.pi/2) * dx + math.cos(angle) * dy),
        (math.sin(angle + math.pi/2) * dx + math.sin(angle) * dy),
    }
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

    ScreenTint = ScreenTint - dt

    local Camera = Engine.camera
    local angle = Camera.angle.x

    local nextX = Camera.pos.x + (math.cos(angle) * DX + math.cos(angle - math.pi/2) * DY) * 0.7
    local nextZ = Camera.pos.z + (math.sin(angle) * DX + math.sin(angle - math.pi/2) * DY) * 0.7

    if not isCoordWall(nextX, nextZ) then
        Camera.pos.x = Camera.pos.x + (math.cos(angle) * DX + math.cos(angle - math.pi/2) * DY) * dt * MY_SPEED
        Camera.pos.z = Camera.pos.z + (math.sin(angle) * DX + math.sin(angle - math.pi/2) * DY) * dt * MY_SPEED
    end

    CurrentPlayer.x = Camera.pos.x
    CurrentPlayer.z = Camera.pos.z

    CurrentPlayer.angle = Camera.angle.x - math.pi/2
    CurrentPlayer.angleY = Camera.angle.y

    for k,v in pairs(Players) do
        updatePlayerPosition(dt, v)
    end
end

function love.draw()
    Scene:render(true, TimeElapsed)

    -- draw HUD
    Scene:renderFunction(
        function ()
            love.graphics.setFont(DefaultFont)
            love.graphics.setColor(FontColor[1], FontColor[2], FontColor[3], 1)
            love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 20)
            love.graphics.print("[c] to capture or release mouse", 20, 40)

            love.graphics.setFont(BigFont)
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
            love.graphics.print("Score: " .. SCORE, GraphicsWidth - 150, GraphicsHeight - 40)
            

            local healthBarWidth = 150
            local healthBarHeight = 20
            local healthBarTop = 20
            local healthBarLeft = GraphicsWidth - healthBarWidth - 20
            local percentHealth = CURRENT_PLAYER_HEALTH / INITIAL_CURRENT_PLAYER_HEALTH

            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle('fill', healthBarLeft, healthBarTop, healthBarWidth * percentHealth, healthBarHeight)
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.rectangle('fill', healthBarLeft + healthBarWidth * percentHealth, healthBarTop, healthBarWidth * (1.0 - percentHealth), healthBarHeight)


            love.graphics.setColor(1, 1, 1, 1)

            local crosshairSize = 30
            local crosshairDistFromCenter = 20

            love.graphics.setLineWidth(2)
            love.graphics.line(GraphicsWidth / 2 - crosshairDistFromCenter - crosshairSize, GraphicsHeight / 2, GraphicsWidth / 2 - crosshairDistFromCenter, GraphicsHeight / 2)
            love.graphics.line(GraphicsWidth / 2 + crosshairDistFromCenter + crosshairSize, GraphicsHeight / 2, GraphicsWidth / 2 + crosshairDistFromCenter, GraphicsHeight / 2)
            love.graphics.line(GraphicsWidth / 2, GraphicsHeight / 2 - crosshairDistFromCenter - crosshairSize, GraphicsWidth / 2, GraphicsHeight / 2 - crosshairDistFromCenter)
            love.graphics.line(GraphicsWidth / 2, GraphicsHeight / 2 + crosshairDistFromCenter + crosshairSize, GraphicsWidth / 2, GraphicsHeight / 2 + crosshairDistFromCenter)

            local minimapSize = 150
            local minimapPadding = 10
            local minimapUnitSize = minimapSize / GRID_SIZE
            local minimapLeft = minimapPadding
            local minimapTop = GraphicsHeight - minimapPadding - minimapSize

            love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
            love.graphics.rectangle('fill', minimapLeft, minimapTop, minimapSize, minimapSize)

            love.graphics.setColor(0.9, 0.9, 0.9, 0.9)
            -- draw walls
            for k,v in pairs(WALLS) do
                love.graphics.rectangle('fill', minimapLeft + v[1] * minimapUnitSize, minimapTop + v[2] * minimapUnitSize, minimapUnitSize, minimapUnitSize)
            end

            -- enemies
            love.graphics.setColor(1.0, 0.0, 0.0, 0.9)
            for k,v in pairs(Players) do
                love.graphics.rectangle('fill', minimapLeft + ((v.x / WALL_SIZE) + GRID_SIZE / 2 - 0.5) * minimapUnitSize, minimapTop + ((v.z / WALL_SIZE) + GRID_SIZE / 2 - 0.5) * minimapUnitSize, minimapUnitSize, minimapUnitSize)
            end

            -- draw user
            love.graphics.setColor(0.0, 0.0, 1.0, 0.9)
            love.graphics.rectangle('fill', minimapLeft + ((CurrentPlayer.x / WALL_SIZE) + GRID_SIZE / 2 - 0.5) * minimapUnitSize, minimapTop + ((CurrentPlayer.z / WALL_SIZE) + GRID_SIZE / 2 - 0.5) * minimapUnitSize, minimapUnitSize, minimapUnitSize)

            love.graphics.setColor(1, 1, 1, 1)
        end, true
    )
end

function love.mousemoved(x,y, dx,dy)
    -- forward mouselook to Scene object for first person camera control
    Scene:mouseLook(x,y, dx,dy)
end
