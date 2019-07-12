
WALL_SIZE = 2.0
GRID_SIZE = 40
ORIGIN_OFFSET = -GRID_SIZE / 2.0
GRID = {}

function getPath(startX, startZ, endX, endZ)
    local worldSize = (GRID_SIZE / 2.0) * WALL_SIZE

    local startXGrid = math.floor((startX + worldSize) / WALL_SIZE)
    local startZGrid = math.floor((startZ + worldSize) / WALL_SIZE)

    local endXGrid = math.floor((endX + worldSize) / WALL_SIZE)
    local endZGrid = math.floor((endZ + worldSize) / WALL_SIZE)

    local seenCoords = {}
    local bfsResult = search(startXGrid, startZGrid, endXGrid, endZGrid, seenCoords, 0)

    --print(bfsResult.depth .. ' ' .. bfsResult.dx .. ' ' .. bfsResult.dz)
    --setTestWall(bfsResult.dx + startXGrid, bfsResult.dz + startZGrid)
    return {
        nextX = (bfsResult.dx + startXGrid + ORIGIN_OFFSET + 0.5) * WALL_SIZE,
        nextZ = (bfsResult.dz + startZGrid + ORIGIN_OFFSET + 0.5) * WALL_SIZE,
    }
end

function search(sx, sz, ex, ez, cache, recursiveDepth)
    local cacheKey = sx .. '-' .. sz

    if sx == ex and sz == ez then
        return {
            depth = 0,
            dx = 0,
            dz = 0,
        }
    end

    if cache[cacheKey] then
        return cache[cacheKey]
    end

    if sx < 1 or sz < 1 or sx > GRID_SIZE or sz > GRID_SIZE or recursiveDepth > 4 or GRID[sx][sz] then
        return {
            depth = 100000,
            dx = 0,
            dz = 0,
        }
    end

    local lowestDepth = 100000
    local currentResult = nil
    local currentDx = 0
    local currentDz = 0

    for dx = -1, 1 do
        for dz = -1, 1 do
            if math.abs(dx) + math.abs(dz) == 1 then
                local recursiveResult = search(sx + dx, sz + dz, ex, ez, cache, recursiveDepth + 1)
                if recursiveResult.depth < lowestDepth then
                    currentResult = recursiveResult
                    lowestDepth = recursiveResult.depth
                    currentDx = dx
                    currentDz = dz
                end
            end
        end
    end

    if currentResult then
        currentResult = {
            depth = lowestDepth + 1,
            dx = currentDx,
            dz = currentDz,
        }
    else
        currentResult = {
            depth = 100000,
            dx = 0,
            dz = 0,
        }
    end

    cache[cacheKey] = currentResult
    return currentResult
end

function isCoordWall(x, z)
    local worldSize = (GRID_SIZE / 2.0) * WALL_SIZE

    local xgrid = math.floor((x + worldSize) / WALL_SIZE)
    local zgrid = math.floor((z + worldSize) / WALL_SIZE)

    if xgrid < 1 or zgrid < 1 or xgrid > GRID_SIZE or zgrid > GRID_SIZE then
        return false
    end

    return GRID[xgrid][zgrid]
end

function makeWalls()
    for x=1, GRID_SIZE do
        table.insert(GRID, {})

        for z=1, GRID_SIZE do
            table.insert(GRID[x], false)
        end
    end

    makeWall(25, 25)
    makeWall(21, 21)
    makeWall(20, 21)


    TEST_WALL = rectColor({
        {-1, 1, 1,    1,0},
        {1, 1, 1,     0,0},
        {1, 1, -1,    0,1},
        {-1, 1, -1,   1,1}
    }, {0,0,1}, WALL_SIZE / 2.0)
    TEST_WALL:setTransform({0,-100,0})
end

function setTestWall(x, z)
    TEST_WALL:setTransform({(x + ORIGIN_OFFSET + 0.5) * WALL_SIZE, -0.9, (z + ORIGIN_OFFSET + 0.5) * WALL_SIZE})
end

function makeWall(x, z)
    GRID[x][z] = true

    local color = {0.9, 0.9, 0.9}
    local size = WALL_SIZE / 2.0

    local front = rectColor({
        {-1, -1, 1,   1,0},
        {-1, 1, 1,    1,1},
        {1, 1, 1,     0,1},
        {1, -1, 1,    0,0}
    }, color, size)

    local back = rectColor({
        {-1, -1, -1,  1,0},
        {-1, 1, -1,   1,1},
        {1, 1, -1,    0,1},
        {1, -1, -1,   0,0}
    }, color, size)

    local left = rectColor({
        {-1, -1, 1,   0,0},
        {-1, 1, 1,    0,1},
        {-1, 1, -1,   1,1},
        {-1, -1, -1,   1,0}
    }, color, size)

    local right = rectColor({
        {1, -1, 1,    0,1},
        {1, 1, 1,     0,0},
        {1, 1, -1,    1,0},
        {1, -1, -1,   1,1}
    }, color, size)

    local top = rectColor({
        {-1, 1, 1,    1,0},
        {1, 1, 1,     0,0},
        {1, 1, -1,    0,1},
        {-1, 1, -1,   1,1}
    }, color, size)


    local models = {front, back, left, right, top}
    for k,v in pairs(models) do
        v:setTransform({(x + ORIGIN_OFFSET + 0.5) * WALL_SIZE, size / 2.0, (z + ORIGIN_OFFSET + 0.5) * WALL_SIZE})
    end
end
