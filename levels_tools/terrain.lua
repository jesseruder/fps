local terrainModel = nil

function clearTerrain()
    if terrainModel then
        terrainModel.dead = true
    end
end

function terrain(imageDirt, wave)
    if CASTLE_SERVER then
        return
    end

    if terrainModel then
        terrainModel.dead = true
    end

    imageDirt:setWrap('repeat','repeat')

    local groundVerts = {}
    for x = 1, #HEIGHTS-1 do
        for y = 1, #HEIGHTS[x]-1 do
            local worldX = x * GridSize - WorldSize
            local worldY = y * GridSize - WorldSize

            table.insert(groundVerts, {worldX, HEIGHTS[x][y], worldY,    worldX/4, worldY/4})
            table.insert(groundVerts, {worldX+GridSize, HEIGHTS[x+1][y], worldY,    (worldX + GridSize)/4, worldY/4})
            table.insert(groundVerts, {worldX, HEIGHTS[x][y+1], worldY+GridSize,    worldX/4, (worldY + GridSize)/4})


            table.insert(groundVerts, {worldX+GridSize, HEIGHTS[x+1][y], worldY,    (worldX + GridSize)/4, worldY/4})
            table.insert(groundVerts, {worldX+GridSize, HEIGHTS[x+1][y+1], worldY+GridSize,    (worldX + GridSize)/4, (worldY + GridSize)/4})
            table.insert(groundVerts, {worldX, HEIGHTS[x][y+1], worldY+GridSize,    worldX/4, (worldY + GridSize)/4})
        end
    end

    terrainModel = Engine.newModel(groundVerts, imageDirt)
    table.insert(Scene.modelList, terrainModel)

    if wave then
        terrainModel.wave = wave
    end
end
