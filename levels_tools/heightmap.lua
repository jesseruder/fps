
function makeHeightMap()
    HEIGHTS = {}
    local x = -WorldSize
    local xi = 1
    while x <= WorldSize do
        HEIGHTS[xi] = {}

        local y = -WorldSize
        local yi = 1
        while y <= WorldSize do
            HEIGHTS[xi][yi] = 0
            y = y + GridSize
            yi = yi + 1
        end

        x = x + GridSize
        xi = xi + 1
    end
end

function addMountainRelative(px, py, height, slope)
    addMountain(math.floor((WorldSize * 2 * px) / GridSize), math.floor((WorldSize * 2 * py) / GridSize), height, slope)
end

function addMountain(centerX, centerY, height, slope)
    local dist = math.ceil(height / slope)
    for x = centerX - dist, centerX + dist do
        for y = centerY - dist, centerY + dist do
            local percentage = math.sqrt(math.pow(centerX - x, 2) + math.pow(centerY - y, 2)) / dist
            if percentage <= 1.0 then
                local thisHeight = (math.cos(percentage * math.pi) + 1)/2.0 * height
                if HEIGHTS[x] and HEIGHTS[x][y] and thisHeight > HEIGHTS[x][y] then
                    HEIGHTS[x][y] = thisHeight
                end
            end
        end
    end
end

function addCraterRelative(px, py, depth, slope)
    addCrater(math.floor((WorldSize * 2 * px) / GridSize), math.floor((WorldSize * 2 * py) / GridSize), depth, slope)
end

function addCrater(centerX, centerY, depth, slope)
    local dist = math.ceil(depth / slope)
    for x = centerX - dist, centerX + dist do
        for y = centerY - dist, centerY + dist do
            local percentage = math.sqrt(math.pow(centerX - x, 2) + math.pow(centerY - y, 2)) / dist
            if percentage <= 1.0 then
                local thisHeight = (math.cos(percentage * math.pi) + 1)/2.0 * -depth
                if HEIGHTS[x] and HEIGHTS[x][y] and thisHeight < HEIGHTS[x][y] then
                    HEIGHTS[x][y] = thisHeight
                end
            end
        end
    end
end

--[[
 * Determines the point of intersection between a plane defined by a point and a normal vector and a line defined by a point and a direction vector.
 *
 * @param planePoint    A point on the plane.
 * @param planeNormal   The normal vector of the plane.
 * @param linePoint     A point on the line.
 * @param lineDirection The direction vector of the line.
 * @return The point of intersection between the line and the plane, null if the line is parallel to the plane.
 ]]--
function dotVec(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end
function crossVec(a, b)
    return {
        x = a.y*b.z - a.z*b.y,
        y = a.z*b.x - a.x*b.z,
        z = a.x*b.y - a.y*b.x
    }
end
function minusVec(v1, v2)
    return  {
        x = v1.x - v2.x,
        y = v1.y - v2.y,
        z = v1.z - v2.z
    }
end
function normalizeVec(v1)
    local d = math.sqrt(v1.x*v1.x + v1.y*v1.y + v1.z*v1.z)
    return {
        x = v1.x / d,
        y = v1.y / d,
        z = v1.z / d
    }
end

-- line direction must be normalized
function lineIntersection(planePoint, planeNormal, linePoint, lineDirection)
    local t = (dotVec(planeNormal, planePoint) - dotVec(planeNormal, linePoint)) / dotVec(planeNormal, lineDirection)
    return {
        x = linePoint.x + lineDirection.x * t,
        y = linePoint.y + lineDirection.y * t,
        z = linePoint.z + lineDirection.z * t,
    }
end

function _heightAtPoint(x, y)
    if x < -WorldSize or x > WorldSize or y < -WorldSize or y > WorldSize then
        return {
            height = 0,
            normal = {0,1,0}
        }
    end

    local unfloorX = (x + WorldSize) / GridSize
    local unfloorY = (y + WorldSize) / GridSize
    local gridX = math.floor(unfloorX)
    local gridY = math.floor(unfloorY)
    local percentX = unfloorX - gridX
    local percentY = unfloorY - gridY

    if not HEIGHTS[gridX][gridY] then
        return {
            height = 0,
            normal = {0,1,0}
        }
    end

    local baseVec = {
        x = gridX * GridSize - WorldSize,
        y = gridY * GridSize - WorldSize,
        z = HEIGHTS[gridX][gridY]
    }
    local xVec = {
        x = (gridX + 1) * GridSize - WorldSize,
        y = gridY * GridSize - WorldSize,
        z = HEIGHTS[gridX + 1][gridY] or 0
    }
    local yVec = {
        x = gridX * GridSize - WorldSize,
        y = (gridY + 1) * GridSize - WorldSize,
        z = HEIGHTS[gridX][gridY + 1] or 0
    }
    local xyVec = {
        x = (gridX + 1) * GridSize - WorldSize,
        y = (gridY + 1) * GridSize - WorldSize,
        z = HEIGHTS[gridX + 1][gridY + 1] or 0
    }

    -- normal of triangle is 𝑛=(𝑃2−𝑃1)×(𝑃3−𝑃1)
    local normal
    if percentX > percentY then
        -- on the x,y   x+1,y    x+1,y+1  triangle
        normal = normalizeVec(crossVec(minusVec(xVec, baseVec), minusVec(xyVec, baseVec)))
    else
        -- on the x,y   x,y+1    x+1,y+1  triangle
        normal = normalizeVec(crossVec(minusVec(xyVec, baseVec), minusVec(yVec, baseVec)))
    end

    --print(normal.x .. " " .. normal.y .. " " .. normal.z)
    local intersection = lineIntersection(
        baseVec,
        normal,
        {x = x, y = y, z = 0},
        {x = 0, y = 0, z = 1}
    )
    return {
        height = intersection.z,
        normal = normal
    }
end
