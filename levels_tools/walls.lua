
WALL_SIZE = 2.0
GRID_SIZE = 22
ORIGIN_OFFSET = -GRID_SIZE / 2.0
GRID = {}

LEVEL = [[
xxxxxxxxxxxxxxxxxxxx
x             x    x
x    xxxxx    x    x
x    x           xxx
xx  xx  o          x
x   xx        x    x
x   xxxxxx    x    x
x   xxxxxxx   x o  x
x             x    x
x   xx        xxx  x
x   xx   p xxxx    x
x                  x
xxx   x     xx     x
x               x  x
x     xxxxx     x  x
x   xxxx        x  x
x    x       xxxx  x
x    x   x         x
x    o   x   o     x
xxxxxxxxxxxxxxxxxxxx
]]

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

    local worldSx = (sx + ORIGIN_OFFSET + 0.5) * WALL_SIZE
    local worldSz = (sz + ORIGIN_OFFSET + 0.5) * WALL_SIZE
    if (sx == ex and sz == ez) or canSeeCurrentPlayerFrom(worldSx, worldSz) then
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

SPAWN_POINTS = {}
function getSpawnPoint()
    local point = SPAWN_POINTS[1 + math.floor(math.random() * #SPAWN_POINTS)]

    return {point[1] + (math.random() - 0.5) * WALL_SIZE, point[2] + (math.random() - 0.5) * WALL_SIZE}
end

function makeWalls()
    for x=1, GRID_SIZE do
        table.insert(GRID, {})

        for z=1, GRID_SIZE do
            table.insert(GRID[x], false)
        end
    end

    z = 1
    for s in LEVEL:gmatch("[^\r\n]+") do
        for x = 1, #s do
            local c = s:sub(x,x)

            if c == 'x' then
                makeWall(x, z)
            end

            if c == 'p' then
                CURRENT_SPAWN_X = (x + ORIGIN_OFFSET + 0.5) * WALL_SIZE
                CURRENT_SPAWN_Z = (z + ORIGIN_OFFSET + 0.5) * WALL_SIZE
            end

            if c == 'o' then
                table.insert(SPAWN_POINTS, {(x + ORIGIN_OFFSET + 0.5) * WALL_SIZE, (z + ORIGIN_OFFSET + 0.5) * WALL_SIZE})
            end
        end

        z = z + 1
    end


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
