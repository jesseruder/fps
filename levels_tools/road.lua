local roadModels = nil
local roadTriangles = {}
local fakeRoadTriangles = {}
local ROAD_EXTRA_ELEV = 0.1

function ptInTriangle2d(p, p0, p1, p2)
    local A = 1/2 * (-p1.z * p2.x + p0.z * (-p1.x + p2.x) + p0.x * (p1.z - p2.z) + p1.x * p2.z)
    local sign
    if A < 0 then
        sign = -1
    else
        sign = 1
    end

    local s = (p0.z * p2.x - p0.x * p2.z + (p2.z - p0.z) * p.x + (p0.x - p2.x) * p.z) * sign
    local t = (p0.x * p1.z - p0.z * p1.x + (p0.z - p1.z) * p.x + (p1.x - p0.x) * p.z) * sign
    
    return s > 0 and t > 0 and (s + t) < 2 * A * sign
end

function roadHeightAtPoint(x, z, indexHint, useFakeHeight)
    if PREFER_GROUND_HEIGHT then
        return heightAtPoint(x, z)
    end

    local DIST_TO_CHECK = 10
    for idx = indexHint - DIST_TO_CHECK, indexHint + DIST_TO_CHECK do
        local realIdx = idx
        if realIdx <= 0 then
            realIdx = realIdx + #PATH_POINTS
        end
        if realIdx > #PATH_POINTS then
            realIdx = realIdx - #PATH_POINTS
        end

        local tris = roadTriangles
        if useFakeHeight then
            tris = fakeRoadTriangles
        end

        if tris[realIdx] then
            for _,triangle in pairs(tris[realIdx]) do
                local p = {
                    x = x,
                    z = z,
                }
                local t1 = {
                    x = triangle[1][1],
                    y = triangle[1][2],
                    z = triangle[1][3]
                }
                local t2 = {
                    x = triangle[2][1],
                    y = triangle[2][2],
                    z = triangle[2][3]
                }
                local t3 = {
                    x = triangle[3][1],
                    y = triangle[3][2],
                    z = triangle[3][3]
                }

                for dx = 1,3 do
                    for dz = 1,3 do
                        local p2 = {
                            x = p.x + (dx - 2)*0.02,
                            z = p.z + (dz - 2)*0.02
                        }

                        if ptInTriangle2d(p2, t1, t2, t3) then
                            local normal = normalizeVec(crossVec(minusVec(t2, t1), minusVec(t3, t1)))
                        
                            local intersection = lineIntersection(
                                t1,
                                normal,
                                {x = x, y = 0, z = z},
                                {x = 0, y = 1, z = 0}
                            )

                            return {
                                height = intersection.y - ROAD_EXTRA_ELEV,
                                normal = normal
                            }
                        end
                    end
                end
            end
        end
    end

    return heightAtPoint(x, z)
end

function updatePathPoints()
    for k,v in pairs(PATH_POINTS) do
        v[4] = 0.0
        -- 5 is "Fake height" used for shells and for car roadindex calculations
        v[5] = 0.0
    end
end

function makeJump(index, length, height)
    if not length then
        length = 5.0
    end

    if not height then
        height = 2.0
    end

    local currHeight = 0.0
    local heightInc = height / length

    for idx = index, index + length do
        currHeight = currHeight + heightInc

        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
    end

    for idx = index + length - 1, index + length*2 - 1 do
        currHeight = currHeight - heightInc

        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
    end
end

function makeEmptyJump(index, length, height, emptyLength, downAmt, ignoreEnd)
    if not length then
        length = 5.0
    end

    if not height then
        height = 2.0
    end

    if not emptyLength then
        emptyLength = 5.0
    end

    if not downAmt then
        downAmt = -0.7
    end

    local currHeight = 0.0
    local heightInc = height / length
    local currIdx

    for idx = index, index + length do
        currHeight = currHeight + heightInc

        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
        currIdx = idx
    end

    for idx = currIdx, currIdx + emptyLength do
        PATH_POINTS[idx][4] = -10000
        PATH_POINTS[idx][5] = currHeight
        currIdx = idx
    end

    if not ignoreEnd then
        currHeight = currHeight + downAmt
        for idx = currIdx, currIdx + length do
            currHeight = currHeight - heightInc

            PATH_POINTS[idx][4] = currHeight
            PATH_POINTS[idx][5] = currHeight
            currIdx = idx
        end
    end
end

function makeSinHill(index, length, height)
    local inc = math.pi / length
    local acc = 0

    for idx = index, index + length do
        PATH_POINTS[idx][4] = math.sin(acc) * height
        PATH_POINTS[idx][5] = math.sin(acc) * height

        acc = acc + inc
    end
end

function makeTabletopJump(index, length, height, topLength)
    if not length then
        length = 5.0
    end

    if not height then
        height = 2.0
    end

    if not topLength then
        topLength = 5.0
    end

    local currHeight = 0.0
    local heightInc = height / length
    local currIdx

    for idx = index, index + length do
        currHeight = currHeight + heightInc

        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
        currIdx = idx
    end

    for idx = currIdx, currIdx + topLength do
        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
        currIdx = idx
    end

    for idx = currIdx, currIdx + length do
        currHeight = currHeight - heightInc

        PATH_POINTS[idx][4] = currHeight
        PATH_POINTS[idx][5] = currHeight
        currIdx = idx
    end
end

function makeRoad(imageRoad, imageWall, roadTexCoordInc, texCoordInc, onlyShowEveryNWall, wallSizePerc)
    if roadModels then
        for k,v in pairs(roadModels) do
            v.dead = true
        end
    end

    if not CASTLE_SERVER then
        MinimapSize = 200
        MinimapPadding = 10
        MinimapInnerSize = MinimapSize - MinimapPadding * 2.0
        MinimapCanvas = love.graphics.newCanvas(MinimapSize, MinimapSize)
        love.graphics.setCanvas(MinimapCanvas)
        love.graphics.setLineWidth(4)
        imageRoad:setWrap('repeat','repeat')
    end

    roadModels = {}

    local elev = ROAD_EXTRA_ELEV

    local lastPoint = PATH_POINTS[#PATH_POINTS]
    local finishLineTexY = 0
    local finishLineTexInc = 1
    local currTexCoord = 0.0
    local currRoadTexCoord = 0.0

    if not texCoordInc then
        texCoordInc = 0.1
    end
    
    if not roadTexCoordInc then
        roadTexCoordInc = 1.0
    end

    if not wallSizePerc then
        wallSizePerc = 0.0
    end

    local numWall = 0

    local allRoadVerts = {}
    local allWallVerts = {}
    local isLastFake = false
    local isLastLastFake = false

    for k,v in pairs(PATH_POINTS) do
        if not CASTLE_SERVER then
            if k > 1 and k < 4 then
                love.graphics.setColor(0,0,0,1)
            else
                love.graphics.setColor(0.8,0.8,0.8,1)
            end

            love.graphics.line(lastPoint[1] * MinimapInnerSize + MinimapPadding,
                lastPoint[2] * MinimapInnerSize + MinimapPadding,
                v[1] * MinimapInnerSize + MinimapPadding,
                v[2] * MinimapInnerSize + MinimapPadding)
        end

        local lx = lastPoint[1] * RoadScale - RoadScale / 2.0
        local ly = lastPoint[2] * RoadScale - RoadScale / 2.0
        local la = lastPoint[3]
        local ldx = math.cos(la + math.pi/2) * RoadRadius
        local ldy = math.sin(la + math.pi/2) * RoadRadius

        local x = v[1] * RoadScale - RoadScale / 2.0
        local y = v[2] * RoadScale - RoadScale / 2.0
        local a = v[3]
        local dx = math.cos(a + math.pi/2) * RoadRadius
        local dy = math.sin(a + math.pi/2) * RoadRadius

        local texCoordBegin = currRoadTexCoord
        local texCoordEnd = currRoadTexCoord + roadTexCoordInc
        local isFinishLine = false
        if k > 1 and k < 4 then
            isFinishLine = true
            texCoordBegin = finishLineTexY
            texCoordEnd = finishLineTexY + finishLineTexInc
            finishLineTexY = finishLineTexY + finishLineTexInc
        end

        local h1 = heightAtPoint(lx - ldx, ly - ldy).height
        local h2 = heightAtPoint(x - dx, y - dy).height
        local h3 = heightAtPoint(x + dx, y + dy).height
        local h4 = heightAtPoint(lx + ldx, ly + ldy).height

        local minHeightLast = math.min(h1, h4) + lastPoint[4]
        local minHeightCurrent = math.min(h2, h3) + v[4]

        local verts = {
            {lx - ldx, elev + math.max(h1, minHeightLast), ly - ldy,    0, texCoordBegin},
            {x - dx, elev + math.max(h2, minHeightCurrent), y - dy,   0,texCoordEnd},
            {x + dx, elev + math.max(h3, minHeightCurrent), y + dy,     1,texCoordEnd},
            {lx + ldx, elev + math.max(h4, minHeightLast), ly + ldy,    1,texCoordBegin}
        }

        local fakeMinHeightLast = math.min(h1, h4) + lastPoint[5]
        local fakeMinHeightCurrent = math.min(h2, h3) + v[5]

        local fakeVerts = {
            {lx - ldx, elev + math.max(h1, fakeMinHeightLast), ly - ldy,    0, texCoordBegin},
            {x - dx, elev + math.max(h2, fakeMinHeightCurrent), y - dy,   0,texCoordEnd},
            {x + dx, elev + math.max(h3, fakeMinHeightCurrent), y + dy,     1,texCoordEnd},
            {lx + ldx, elev + math.max(h4, fakeMinHeightLast), ly + ldy,    1,texCoordBegin}
        }

        if not CASTLE_SERVER and lastPoint[4] > -100 and v[4] > -100 then
            if isFinishLine then
                local model = rect(verts, imageFinishLine)
                table.insert(roadModels, model)
            else
                addRectVerts(allRoadVerts, verts)
            end

            if imageWall and not v[6] then
                local subtract = 0.0
                if wallSizePerc > 0.0 then
                    subtract = 0.05
                end
                local heightLeftOld = (1 - wallSizePerc / RoadRadius) * verts[1][2] + (wallSizePerc / RoadRadius) * verts[4][2] - subtract
                local heightRightOld = (wallSizePerc / RoadRadius) * verts[1][2] + (1 - wallSizePerc / RoadRadius) * verts[4][2] - subtract
                local heightLeftNew = (1 - wallSizePerc / RoadRadius) * verts[2][2] + (wallSizePerc / RoadRadius) * verts[3][2] - subtract
                local heightRightNew = (wallSizePerc / RoadRadius) * verts[2][2] + (1 - wallSizePerc / RoadRadius) * verts[3][2] - subtract
                addRectVerts(allWallVerts, {
                    {verts[1][1] + ldx * wallSizePerc, heightLeftOld, verts[1][3]+ ldy * wallSizePerc, currTexCoord, verts[1][2] + 5},-- last
                    {verts[2][1] + dx * wallSizePerc, heightLeftNew, verts[2][3] + dy * wallSizePerc, currTexCoord + texCoordInc, verts[2][2] + 5},
                    {verts[2][1] + dx * wallSizePerc, -5, verts[2][3] - dy * wallSizePerc,   currTexCoord + texCoordInc, 0},
                    {verts[1][1] + ldx * wallSizePerc, -5, verts[1][3] - ldy * wallSizePerc,   currTexCoord, 0},-- last
                })

                addRectVerts(allWallVerts, {
                    {verts[3][1] - dx * wallSizePerc, heightRightNew, verts[3][3] - dy * wallSizePerc, currTexCoord, verts[3][2] + 5},-- last
                    {verts[4][1] - ldx * wallSizePerc, heightRightOld, verts[4][3] - ldy * wallSizePerc, currTexCoord + texCoordInc, verts[4][2] + 5},
                    {verts[4][1] - ldx * wallSizePerc, -5, verts[4][3] - ldy * wallSizePerc,   currTexCoord + texCoordInc, 0},
                    {verts[3][1] - dx * wallSizePerc, -5, verts[3][3] - dy * wallSizePerc,   currTexCoord, 0},-- last
                })

                if onlyShowEveryNWall == nil or onlyShowEveryNWall == numWall then
                    numWall = 0
                    -- for empty jump
                    if isLastLastFake then
                        addRectVerts(allWallVerts, {
                            {verts[1][1], verts[1][2], verts[1][3], 0, verts[1][2] + 5},-- last
                            {verts[4][1], verts[4][2], verts[4][3], RoadRadius * 2, verts[4][2] + 5},
                            {verts[4][1], -5, verts[4][3],   RoadRadius * 2, 0},
                            {verts[1][1], -5, verts[1][3],   0, 0},-- last
                        })
                    end

                    addRectVerts(allWallVerts, {
                        {verts[3][1], verts[3][2], verts[3][3], 0, verts[3][2] + 5},-- last
                        {verts[2][1], verts[2][2], verts[2][3], RoadRadius * 2, verts[2][2] + 5},
                        {verts[2][1], -5, verts[2][3],   RoadRadius * 2, 0},
                        {verts[3][1], -5, verts[3][3],   0, 0},-- last
                    })
                end
            end
        end

        roadTriangles[k] = {
            {verts[1], verts[2], verts[4]},
            {verts[2], verts[3], verts[4]}
        }

        fakeRoadTriangles[k] = {
            {fakeVerts[1], fakeVerts[2], fakeVerts[4]},
            {fakeVerts[2], fakeVerts[3], fakeVerts[4]}
        }

        isLastLastFake = isLastFake
        isLastFake = v[4] ~= v[5]
        lastPoint = v
        currTexCoord = currTexCoord + texCoordInc
        currRoadTexCoord = currRoadTexCoord + roadTexCoordInc
        numWall = numWall + 1
    end

    if not CASTLE_SERVER then
        love.graphics.setCanvas()

        local model = modelFromCoords(allRoadVerts, imageRoad)
        table.insert(roadModels, model)

        if imageWall then
            model = modelFromCoords(allWallVerts, imageWall)
            table.insert(roadModels, model)
        end
    end
end
