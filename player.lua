
ScreenTint = 0.0

function playerHit(player)
    if player.models then
        for k,v in pairs(player.models) do
            v.tintColor = {1.0, 0.0, 0.0}
        end
        player.tintCountdown = 0.1
    else
        ScreenTint = 0.1
        CURRENT_PLAYER_HEALTH = CURRENT_PLAYER_HEALTH - 1

        if CURRENT_PLAYER_HEALTH <= 0 then
            CURRENT_PLAYER_HEALTH = INITIAL_CURRENT_PLAYER_HEALTH
            SCORE = SCORE - PENALTY_FOR_DYING
            if SCORE < 0 then
                SCORE = 0
            end
        end
    end

    Scene:explosion(player.x, player.y, player.z)

    if player.health then
        player.health = player.health - 1
        if player.health == 0 then
            player.isDead = true
            SCORE = SCORE + 1
        end
    end
end

function createPlayer()
    local spawn = getSpawnPoint()

    local Player = {
        color = {0.7, 0.7, 0.7},
        size = 0.5,
        angle = 0.0,
        angleY = 0.0,
        x = spawn[1],
        y = 0.5,
        z = spawn[2],
        health = STARTING_HEALTH,
        speed = ENEMY_SPEED,
        bulletCountdown = 1.0,
        isRendered = true,
    }

    local front = rectColor({
        {-1, -1, 1,   1,0},
        {-1, 1, 1,    1,1},
        {1, 1, 1,     0,1},
        {1, -1, 1,    0,0}
    }, Player.color, Player.size)

    local back = rectColor({
        {-1, -1, -1,  1,0},
        {-1, 1, -1,   1,1},
        {1, 1, -1,    0,1},
        {1, -1, -1,   0,0}
    }, Player.color, Player.size)

    local left = rectColor({
        {-1, -1, 1,   0,0},
        {-1, 1, 1,    0,1},
        {-1, 1, -1,   1,1},
        {-1, -1, -1,   1,0}
    }, Player.color, Player.size)

    local right = rectColor({
        {1, -1, 1,    0,1},
        {1, 1, 1,     0,0},
        {1, 1, -1,    1,0},
        {1, -1, -1,   1,1}
    }, Player.color, Player.size)

    local top = rectColor({
        {-1, 1, 1,    1,0},
        {1, 1, 1,     0,0},
        {1, 1, -1,    0,1},
        {-1, 1, -1,   1,1}
    }, Player.color, Player.size)




    local eyeSize = 0.4
    local eyeDistFromSide = 0.25
    local eyeDistFromTop = 0.6

    local pupilSize = 0.25
    local pupilDistFromSide = eyeDistFromSide + (eyeSize - pupilSize) * 0.5
    local pupilDistFromTop = eyeDistFromTop + (eyeSize - pupilSize) * 0.5
    local eyeColor = {0.0, 1.0, 0.0}

    local whiteVerts = {}
    local colorVerts = {}

    addRectVerts(whiteVerts, {
        {1.02, 1 - eyeDistFromTop - eyeSize, 1 - eyeDistFromSide},
        {1.02, 1 - eyeDistFromTop, 1 - eyeDistFromSide},
        {1.02, 1 - eyeDistFromTop, 1 - eyeDistFromSide - eyeSize},
        {1.02, 1 - eyeDistFromTop - eyeSize, 1 - eyeDistFromSide - eyeSize}
    })

    addRectVerts(colorVerts, {
        {1.04, 1 - pupilDistFromTop - pupilSize, 1 - pupilDistFromSide},
        {1.04, 1 - pupilDistFromTop, 1 - pupilDistFromSide},
        {1.04, 1 - pupilDistFromTop, 1 - pupilDistFromSide - pupilSize},
        {1.04, 1 - pupilDistFromTop - pupilSize, 1 - pupilDistFromSide - pupilSize}
    })

    addRectVerts(whiteVerts, {
        {1.02, 1 - eyeDistFromTop - eyeSize, -1 + eyeDistFromSide},
        {1.02, 1 - eyeDistFromTop, -1 + eyeDistFromSide},
        {1.02, 1 - eyeDistFromTop, -1 + eyeDistFromSide + eyeSize},
        {1.02, 1 - eyeDistFromTop - eyeSize, -1 + eyeDistFromSide + eyeSize}
    })

    addRectVerts(colorVerts, {
        {1.04, 1 - pupilDistFromTop - pupilSize, -1 + pupilDistFromSide},
        {1.04, 1 - pupilDistFromTop, -1 + pupilDistFromSide},
        {1.04, 1 - pupilDistFromTop, -1 + pupilDistFromSide + pupilSize},
        {1.04, 1 - pupilDistFromTop - pupilSize, -1 + pupilDistFromSide + pupilSize}
    })

    local whiteModel = modelFromCoordsColor(whiteVerts, {1,1,1,1}, Player.size)
    local colorModel = modelFromCoordsColor(colorVerts, eyeColor, Player.size)

    Player.models = {front, back, left, right, top, whiteModel, colorModel}

    return Player
end

function normalizeAngle(angle)
    return math.fmod(angle, 2.0 * math.pi)
end

function updatePlayerPosition(dt, player)
    if not player.isRendered then
        return
    end

    if player.isDead then
        player.isDead = false
        player.health = STARTING_HEALTH

        local spawn = getSpawnPoint()
        player.x = spawn[1]
        player.z = spawn[2]
        player.angle = 0.0
        player.angleY = 0.0
    end

    if not player.angleUp then
        player.angleUp = 0
    end

    if not player.angleSide then
        player.angleSide = 0
    end

    if player.tintCountdown and player.tintCountdown > 0.0 then
        player.tintCountdown = player.tintCountdown - dt
        if player.tintCountdown <= 0.0 then
            for k,v in pairs(player.models) do
                v.tintColor = nil
            end
        end
    end

    player.bulletCountdown = player.bulletCountdown - dt

    local desiredAngle = 0
    if canSeeCurrentPlayerFrom(player.x, player.z) then
        desiredAngle = math.atan2(CurrentPlayer.z - player.z, CurrentPlayer.x - player.x)

        if player.bulletCountdown < 0.0 then
            fireBullet(player)
            player.bulletCountdown = 1.0
        end
    else
        local goalCoords = getPath(player.x, player.z, CurrentPlayer.x, CurrentPlayer.z)
        desiredAngle = math.atan2(goalCoords.nextZ - player.z, goalCoords.nextX - player.x)
    end

    local diffAngle = desiredAngle - normalizeAngle(player.angle)

    if math.abs(diffAngle - math.pi * 2.0) < math.abs(diffAngle) then
        diffAngle = diffAngle - math.pi * 2.0
    elseif math.abs(diffAngle + math.pi * 2.0) < math.abs(diffAngle) then
        diffAngle = diffAngle + math.pi * 2.0
    end

    if diffAngle > 0 then
        player.angle = player.angle + dt * ENEMY_ROTATION_SPEED
    else
        player.angle = player.angle - dt * ENEMY_ROTATION_SPEED
    end

    local nextX = player.x + math.cos(player.angle) * 0.7
    local nextZ = player.z + math.sin(player.angle) * 0.7

    if not isCoordWall(nextX, nextZ) then
        player.x = player.x + math.cos(player.angle) * dt * player.speed
        player.z = player.z + math.sin(player.angle) * dt * player.speed
    end

    for k,v in pairs(player.models) do
        v:setTransform({player.x, player.y, player.z}, {-player.angle, cpml.vec3.unit_y, player.angleUp, cpml.vec3.unit_z, player.angleSide, cpml.vec3.unit_x})
    end
end