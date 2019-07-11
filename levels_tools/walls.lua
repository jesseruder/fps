
WALL_SIZE = 2.0
GRID_SIZE = 40
ORIGIN_OFFSET = -GRID_SIZE / 2.0
GRID = {}

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
