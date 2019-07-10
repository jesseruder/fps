local skyboxModels = nil

SkyboxHeight = 15
function skybox(imageSkybox, lowY, top, fogAmount)
    if CASTLE_SERVER then
        return
    end

    if not top then
        top = SkyboxHeight
    end

    if skyboxModels then
        for k,v in pairs(skyboxModels) do
            v.dead = true
        end
    end

    if not lowY then
        lowY = -15
    end

    if not fogAmount then
        fogAmount = 0.0
    end

    -- front
    local front = rect({
        {-WorldSize, lowY, -WorldSize,                 0.25, 0.6666},
        {-WorldSize, top, -WorldSize,      0.25, 0.3333},
        {WorldSize, top, -WorldSize,       0.5, 0.3333},
        {WorldSize, lowY, -WorldSize,                  0.5, 0.6666}
    }, imageSkybox, nil, fogAmount)

    -- right
    local right = rect({
        {WorldSize, lowY, -WorldSize,                 0.5, 0.6666},
        {WorldSize, top, -WorldSize,      0.5, 0.3333},
        {WorldSize, top, WorldSize,       0.75, 0.3333},
        {WorldSize, lowY, WorldSize,                  0.75, 0.6666}
    }, imageSkybox, nil, fogAmount)

    -- back
    local back = rect({
        {WorldSize, lowY, WorldSize,                 0.75, 0.6666},
        {WorldSize, top, WorldSize,      0.75, 0.3333},
        {-WorldSize, top, WorldSize,       1, 0.3333},
        {-WorldSize, lowY, WorldSize,                  1, 0.66666}
    }, imageSkybox, nil, fogAmount)

    -- left
    local left = rect({
        {-WorldSize, lowY, WorldSize,                 0, 0.6666},
        {-WorldSize, top, WorldSize,      0, 0.3333},
        {-WorldSize, top, -WorldSize,       0.25, 0.3333},
        {-WorldSize, lowY, -WorldSize,                  0.25, 0.6666}
    }, imageSkybox, nil, fogAmount)

    -- top
    local top = rect({
        {-WorldSize, top, -WorldSize,     0.25, 0.3333},
        {WorldSize, top, -WorldSize,      0.5, 0.3333},
        {WorldSize, top, WorldSize,       0.5, 0},
        {-WorldSize, top, WorldSize,      0.25, 0}
    }, imageSkybox, nil, fogAmount)

    -- bottom
    local bottom = rect({
        {-WorldSize, lowY + 0.1, -WorldSize - 0.1,                 0.25, 0.6666},
        {-WorldSize, lowY + 0.1, WorldSize + 0.1,      0.25, 1.0},
        {WorldSize, lowY + 0.1, WorldSize + 0.1,       0.5, 1.0},
        {WorldSize, lowY + 0.1, -WorldSize - 0.1,                  0.5, 0.6666}
    }, imageSkybox, nil, fogAmount)

    skyboxModels = {front, right, back, left, top, bottom}
end
