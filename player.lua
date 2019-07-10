
function createPlayer()
    local Player = {
        color = {0.7, 0.7, 0.7},
        size = 0.4,
        angle = 0.0,
        x = 0.0,
        y = 0.2,
        z = 0.0,
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
    local eyeColor = {0.0, 0.0, 1.0}

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

function updatePlayerPosition(player)
    if not player.angleUp then
        player.angleUp = 0
    end

    if not player.angleSide then
        player.angleSide = 0
    end

    for k,v in pairs(player.models) do
        v:setTransform({player.x, player.size / 2.0 + player.y, player.z}, {-player.angle, cpml.vec3.unit_y, player.angleUp, cpml.vec3.unit_z, player.angleSide, cpml.vec3.unit_x})
    end
end