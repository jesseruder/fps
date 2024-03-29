-- Super Simple 3D Engine v1
-- groverburger 2019

cpml = require "cpml"

local engine = {}
engine.objFormat = { 
    {"VertexPosition", "float", 4}, 
    {"VertexTexCoord", "float", 2}, 
    {"VertexNormal", "float", 3}, 
}


-- create a new Model object
-- given a table of verts for example: { {0,0,0}, {0,1,0}, {0,0,1} }
-- each vert is its own table that contains three coordinate numbers, and may contain 2 extra numbers as uv coordinates
-- another example, this with uvs: { {0,0,0, 0,0}, {0,1,0, 1,0}, {0,0,1, 0,1} }
-- polygons are automatically created with three consecutive verts
function engine.newModel(verts, texture, coords, color, format, scale, fogAmount)
    local m = {}

    -- default values if no arguments are given
    if coords == nil then
        coords = {0,0,0}
    end
    if scale == nil then
        scale = 1.0
    end
    if color == nil then
        color = {1,1,1}
    end
    if format == nil then
        format = { 
            {"VertexPosition", "float", 3}, 
            {"VertexTexCoord", "float", 2}, 
        }
    end
    if texture == nil then
        texture = love.graphics.newCanvas(1,1)
        love.graphics.setCanvas(texture)
        love.graphics.clear(unpack(color))
        love.graphics.setCanvas()
    end
    if verts == nil then
        verts = {}
    end

    -- translate verts by given coords
    for i=1, #verts do
        if coords[1] ~= 0.0 or coords[2] ~= 0.0 or coords[3] ~= 0.0 or scale ~= 1.0 then
            local newVert = {}
            newVert[1] = (verts[i][1] + coords[1]) * scale
            newVert[2] = (verts[i][2] + coords[2]) * scale
            newVert[3] = (verts[i][3] + coords[3]) * scale
            newVert[4] = verts[i][4]
            newVert[5] = verts[i][5]
            verts[i] = newVert
        end

        -- if not given uv coordinates, put in random ones
        if #verts[i] < 5 then
            verts[i][4] = love.math.random()
            verts[i][5] = love.math.random()
        end
    end

    -- define the Model object's properties
    m.mesh = nil
    if #verts > 0 then
        m.mesh = love.graphics.newMesh(format, verts, "triangles")
        m.mesh:setTexture(texture)
    end
    m.texture = texture
    m.format = format
    m.verts = verts
    m.transform = TransposeMatrix(cpml.mat4.identity())
    m.color = color
    m.visible = true
    m.dead = false
    m.wireframe = false
    m.culling = false
    m.fogAmount = fogAmount

    m.setVerts = function (self, verts)
        if #verts > 0 then
            self.mesh = love.graphics.newMesh(self.format, verts, "triangles")
            self.mesh:setTexture(self.texture)
        end
        self.verts = verts
    end

    -- translate and rotate the Model
    m.setTransform = function (self, coords, rotations)
        if angle == nil then
            angle = 0
            axis = cpml.vec3.unit_y
        end
        self.transform = cpml.mat4.identity()
        self.transform:translate(self.transform, cpml.vec3(unpack(coords)))
        if rotations ~= nil then
            for i=1, #rotations, 2 do
                self.transform:rotate(self.transform, rotations[i],rotations[i+1])
            end
        end
        self.transform = TransposeMatrix(self.transform)
    end

    -- returns a list of the verts this Model contains
    m.getVerts = function (self)
        local ret = {}
        for i=1, #self.verts do
            ret[#ret+1] = {self.verts[i][1], self.verts[i][2], self.verts[i][3]}
        end

        return ret
    end

    -- prints a list of the verts this Model contains
    m.printVerts = function (self)
        local verts = self:getVerts()
        for i=1, #verts do
            print(verts[i][1], verts[i][2], verts[i][3])
            if i%3 == 0 then
                print("---")
            end
        end
    end

    -- set a texture to this Model
    m.setTexture = function (self, tex)
        self.mesh:setTexture(tex)
    end

    -- check if this Model must be destroyed
    -- (called by the parent Scene model's update function automatically)
    m.deathQuery = function (self)
        return not self.dead
    end

    return m
end

-- create a new Scene object with given canvas output size
function engine.newScene(renderWidth,renderHeight)
	love.graphics.setDepthMode("lequal", true)
    local scene = {}

    local particleVerts = {}
    for i = 0, 100000 do
        table.insert(particleVerts, {
            math.random() * 100 - 50,
            math.random() * 1 - 100,
            math.random() * 100 - 50,
        })
    end
    scene.particles = love.graphics.newMesh({
        {"VertexPosition", "float", 3},
    }, particleVerts, "points")

    local explosionParticleVerts = {}
    for i = 0, 100000 do
        table.insert(explosionParticleVerts, {
            0.0,
            -10.0,
            0.0,
            0.0,
            -10.0,
            0.0,
            0.0,
        })
    end
    scene.explosionParticles = love.graphics.newMesh({
        {"VertexPosition", "float", 3},
        {"endPosition", "float", 3},
        {"startTime", "float", 1},
        {"explosionSize", "float", 1}
    }, explosionParticleVerts, "points")
    scene.explosionParticles:setTexture(love.graphics.newImage("assets/explosion.png"))
    scene.currentExplosionIdx = 1

    EXPLOSION_START_DIST = 0.7
    EXPLOSION_DIST = 3.0
    scene.explosion = function (self, x, y, z)
        for i = 1, 40 do
            local rx = (math.random() - 0.5)
            local ry = (math.random() - 0.5)
            local rz = (math.random() - 0.5)

            explosionParticleVerts[scene.currentExplosionIdx] = {
                x + rx * EXPLOSION_START_DIST,
                y + ry * EXPLOSION_START_DIST,
                z + rz * EXPLOSION_START_DIST,
                x + rx * EXPLOSION_DIST,
                y + ry * EXPLOSION_DIST,
                z + rz * EXPLOSION_DIST,
                TimeElapsed + math.random() * 0.3,
                8.0,
            }

            scene.currentExplosionIdx = scene.currentExplosionIdx + 1
            if scene.currentExplosionIdx >= 100000 then
                scene.currentExplosionIdx = 1
            end
        end

        scene.explosionParticles:setVertices(explosionParticleVerts)
    end

    scene.smallExplosion = function (self, x, y, z)
        for i = 1, 3 do
            local rx = (math.random() - 0.5)
            local ry = (math.random() - 0.5)
            local rz = (math.random() - 0.5)

            explosionParticleVerts[scene.currentExplosionIdx] = {
                x + rx * EXPLOSION_START_DIST * 0.2,
                y + ry * EXPLOSION_START_DIST * 0.2,
                z + rz * EXPLOSION_START_DIST * 0.2,
                x + rx * EXPLOSION_DIST * 0.2,
                y + ry * EXPLOSION_DIST * 0.2,
                z + rz * EXPLOSION_DIST * 0.2,
                TimeElapsed + math.random() * 0.3,
                0.5,
            }

            scene.currentExplosionIdx = scene.currentExplosionIdx + 1
            if scene.currentExplosionIdx >= 100000 then
                scene.currentExplosionIdx = 1
            end
        end

        scene.explosionParticles:setVertices(explosionParticleVerts)
    end

    -- define the shaders used in rendering the scene
    scene.threeShader = love.graphics.newShader[[
        uniform mat4 view;
        uniform mat4 model_matrix;
        uniform float fog_amt;
        uniform float fog_startDist;
        uniform float fog_divide;
        uniform float wave;
        uniform float time;
        uniform vec4 fogColor;
        varying float fogDistance;

        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vec4 p = vertex_position;
            if (wave > 0.0) {
                p.y = p.y + 0.1 * sin(time * 0.5 + p.z * 0.7) + 0.1 * sin(time * 0.7 + 1.0 + p.x * 1.2);
            }

            vec4 result = view * model_matrix * p;
            fogDistance = length(result.xyz);
            return result;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 coords = texture_coords;
            if (wave > 0.0) {
                coords = coords + vec2(0.1 * sin(time + coords.y), 0.1 * sin(time * 0.3 + 1.0 + coords.x * 2.0));
            }

            vec4 texturecolor = Texel(texture, coords);
            //if the alpha here is close to zero just don't draw anything here
            if (texturecolor.a == 0.0)
            {
                discard;
            }

            float fogAmount = 0.0;
            if (fogDistance > fog_startDist) {
                // start fog
                fogAmount = (fogDistance - fog_startDist) / fog_divide;
                if (fogAmount > 0.7) {
                    fogAmount = 0.7;
                }
                fogAmount = fogAmount * fog_amt;
            }

            return (color*texturecolor*(1.0 - fogAmount)) + (fogColor * fogAmount);
        }
        #endif
    ]]

    --PARTICLES_ENABLED = true
    scene.particleShader = love.graphics.newShader[[
        uniform mat4 view;
        uniform float time;
        varying float dist;

        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vec4 p = vertex_position;
            p.y = p.y - time * 0.015;
            p.y = mod(p.y, 1.0);
            p.y = p.y * 100.0 - 50.0;
            vec4 result = view * p;
            dist = length(result.xyz);
            return result;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 coord = gl_PointCoord - vec2(0.5);
            float radius = 0.5;
            radius = 10.0 * radius / dist;

            if (radius > 0.5) {
                radius = 0.5;
            }

            if(length(coord) > radius)
                discard;

            return vec4(1.0, 1.0, 1.0, 0.8);
            //return Texel(texture, gl_PointCoord);
        }
        #endif
    ]]

    scene.explosionShader = love.graphics.newShader[[
        uniform mat4 view;
        uniform float time;
        uniform vec3 cameraPos;
        varying float dist;
        varying float percentDone;
        varying float explosionSizeV;

        #ifdef VERTEX
        attribute vec3 endPosition;
        attribute float startTime;
        attribute float explosionSize;

        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            if (time - startTime > 0.5) {
                return vec4(2.0, 2.0, 0.0, 1.0);
            }

            float percent = (time - startTime) / 0.5;
            vec4 vec = vec4(endPosition.x, endPosition.y, endPosition.z, 1.0) - vertex_position;
            vec4 pos = vertex_position + vec * percent;

            dist = length(vec3(pos.x, pos.y, pos.z) - cameraPos);
            percentDone = percent;
            explosionSizeV = explosionSize;

            vec4 result = view * pos;
            return result;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 coord = gl_PointCoord - vec2(0.5);
            float radius = 0.5;
            radius = explosionSizeV * radius / dist;

            if (radius > 0.5) {
                radius = 0.5;
            }

            if(length(coord) > radius)
                discard;

            float percentX = ((coord.x / radius) + 1.0) / 2.0;
            float percentY = ((coord.y / radius) + 1.0) / 2.0;

            float idx = floor(percentDone * 16.0);
            float percentToNextIdx = percentDone * 16.0 - idx;
            float xAsset = idx - 4.0 * floor(idx / 4.0);
            float yAsset = floor(idx / 4.0);
            float nextIdx = idx + 1.0;
            if (nextIdx > 15.0) {
                nextIdx = 15.0;
            }

            float xAssetNext = nextIdx - 4.0 * floor(nextIdx / 4.0);
            float yAssetNext = floor(nextIdx / 4.0);

            vec4 currentColor = Texel(texture, vec2(percentX, percentY) * vec2(0.25, 0.25) + vec2(0.25 * xAsset, 0.25 * yAsset));
            vec4 nextColor = Texel(texture, vec2(percentX, percentY) * vec2(0.25, 0.25) + vec2(0.25 * xAssetNext, 0.25 * yAssetNext));

            vec4 result = nextColor * percentToNextIdx + currentColor * (1.0 - percentToNextIdx);
            if (result.a < 0.01 || result.r + result.g + result.b < 0.3) {
                discard;
            }

            return result;
        }
        #endif
    ]]

    scene.bulletShader = love.graphics.newShader[[
        uniform mat4 view;
        uniform float time;

        #ifdef VERTEX
        attribute float startTime;
        
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            float elapsedTime = time - startTime;
            if (elapsedTime > 0.015 || mod(elapsedTime * 10.0, 1.0) > 0.5) {
                return vec4(2.0, 2.0, 0.0, 1.0);
            }

            vec4 p = vertex_position;
            vec4 result = view * p;
            return result;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return vec4(0.0, 1.0, 0.0, 0.8);
        }
        #endif
    ]]

    scene.postProcessingShader = love.graphics.newShader[[
        #ifdef VERTEX
        #endif

        #ifdef PIXEL
        uniform float xPixelSize;
        uniform float yPixelSize;
        uniform float overlayOpacity;

        vec4 blurColor(Image texture, vec2 texture_coords, float size)
        {
            vec4 l = Texel(texture, texture_coords - vec2(xPixelSize * size, 0.0));
            vec4 r = Texel(texture, texture_coords + vec2(xPixelSize * size, 0.0));
            vec4 t = Texel(texture, texture_coords - vec2(0.0, yPixelSize * size));
            vec4 b = Texel(texture, texture_coords + vec2(0.0, yPixelSize * size));
            return (l + r + t + b) / 4.0;
        }

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
        {
            vec4 outColor;
        
            vec4 o = Texel(texture, texture_coords);
            outColor = (o * 2.0 + blurColor(texture, texture_coords, 1.0)) / 3.0;
            
            return outColor * overlayOpacity + vec4(0.0, 0.0, 0.0, 1.0) * (1.0 - overlayOpacity);
        }
        #endif
    ]]

    scene.motionBlurShader = love.graphics.newShader[[
        #ifdef VERTEX
        #endif

        #ifdef PIXEL
        uniform Image oldCanvas;
        uniform float amount;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
        {
            vec4 o = Texel(texture, texture_coords);
            // smear down
            vec4 old = Texel(oldCanvas, texture_coords + vec2(0.0, -0.003));

            return o * (1.0 - amount) + old * amount;
        }
        #endif
    ]]

    scene.renderWidth = renderWidth
    scene.renderHeight = renderHeight

    -- create a canvas that will store the rendered 3d scene
    scene.threeCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.postProcessingCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.motionBlurCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.motionBlurCanvasOld = love.graphics.newCanvas(renderWidth, renderHeight)
    -- create a canvas that will store a 2d layer that can be drawn on top of the 3d scene
    scene.twoCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.modelList = {}

    engine.camera = {
        pos = cpml.vec3(0, 0.6, -1),
        angle = cpml.vec3(1, 0, 0),
        perspective = TransposeMatrix(cpml.mat4.from_perspective(60, renderWidth/renderHeight, 0.1, 10000)),
        transform = cpml.mat4(),
    }
    -- camera.perspective = TransposeMatrix(cpml.mat4.from_perspective(90, love.graphics.getWidth()/love.graphics.getHeight(), 0.001, 10000))

    -- should be called in love.update every frame
    scene.update = function (self)
        local i = 1
        while i<=#(self.modelList) do
            local thing = self.modelList[i]
            if thing:deathQuery() then
                i=i+1
            else
                table.remove(self.modelList, i)
            end
        end
    end

    -- call in love.update for a simple first person camera movement system
    scene.basicCamera = function (self, dt)
        local speed = 5 * dt
        if love.keyboard.isDown("lctrl") then
            speed = speed * 10
        end
        local Camera = engine.camera
        local pos = Camera.pos
        
        local mul = love.keyboard.isDown("w") and 1 or (love.keyboard.isDown("s") and -1 or 0)
        pos.x = pos.x + math.sin(-Camera.angle.x) * mul * speed
        pos.z = pos.z + math.cos(-Camera.angle.x) * mul * speed
        
        local mul = love.keyboard.isDown("d") and -1 or (love.keyboard.isDown("a") and 1 or 0)
        pos.x = pos.x + math.cos(Camera.angle.x) * mul * speed
        pos.z = pos.z + math.sin(Camera.angle.x) * mul * speed

        local mul = love.keyboard.isDown("lshift") and 1 or (love.keyboard.isDown("space") and -1 or 0)
        pos.y = pos.y + mul * speed
    end

    -- renders the models in the scene to the threeCanvas
    -- will draw threeCanvas if drawArg is not given or is true (use if you want to scale the game canvas to window)
    scene.render = function (self, drawArg, timeElapsed)
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(1,1,1)
        love.graphics.setCanvas({self.threeCanvas, depth=true})
        love.graphics.clear(0,0,0,0)
        love.graphics.setShader(self.threeShader)

        local Camera = engine.camera
        Camera.transform = cpml.mat4()
        local t, a = Camera.transform, Camera.angle
        local p = {}
        p.x = Camera.pos.x
        p.y = Camera.pos.y
        p.z = Camera.pos.z

        p.x = p.x * -1
        p.y = p.y * -1
        p.z = p.z * -1
        t:rotate(t, a.y, cpml.vec3.unit_x)
        t:rotate(t, a.x, cpml.vec3.unit_y)
        t:rotate(t, a.z, cpml.vec3.unit_z)
        t:translate(t, p)
        self.threeShader:send("view", Camera.perspective * TransposeMatrix(Camera.transform))
        
        for i=1, #self.modelList do
            local model = self.modelList[i]
            if model ~= nil and model.visible and #model.verts > 0 then

                if model.tintColor then
                    love.graphics.setColor(model.tintColor[1], model.tintColor[2], model.tintColor[3], 1)
                else
                    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
                end

                self.threeShader:send("model_matrix", model.transform)
                local fogAmount = 1.0
                if model.fogAmount then
                    fogAmount = model.fogAmount
                end
                self.threeShader:send("fog_amt", fogAmount)
                self.threeShader:send("fog_divide", FogDivide)
                self.threeShader:send("fog_startDist", FogStartDist)
                self.threeShader:send("fogColor", FogColor)
                local wave = 0.0
                if model.wave then
                    wave = 1.0
                end
                self.threeShader:send("wave", wave)
                self.threeShader:send("time", timeElapsed)
                -- need the inverse to compute normals when model is rotated
                --self.threeShader:send("model_matrix_inverse", TransposeMatrix(InvertMatrix(model.transform)))
                love.graphics.setWireframe(model.wireframe)
                if model.culling then
                    love.graphics.setMeshCullMode("back")
                end
                love.graphics.draw(model.mesh, -self.renderWidth/2, -self.renderHeight/2)
                love.graphics.setMeshCullMode("none")
                love.graphics.setWireframe(false)
            end
        end

        if self.particles and PARTICLES_ENABLED then
            love.graphics.setShader(self.particleShader)
            self.particleShader:send("time", timeElapsed)
            self.particleShader:send("view", Camera.perspective * TransposeMatrix(Camera.transform))
            love.graphics.setPointSize(20)
            love.graphics.draw(self.particles, -self.renderWidth/2, -self.renderHeight/2)
        end

        if self.explosionParticles then
            --love.graphics.setBlendMode("add")
            love.graphics.setShader(self.explosionShader)
            self.explosionShader:send("time", timeElapsed)
            self.explosionShader:send("view", Camera.perspective * TransposeMatrix(Camera.transform))
            self.explosionShader:send("cameraPos", {Camera.pos.x, Camera.pos.y, Camera.pos.z})
            love.graphics.setPointSize(200)
            love.graphics.draw(self.explosionParticles, -self.renderWidth/2, -self.renderHeight/2)
            --love.graphics.setBlendMode("alpha")
        end

        if BulletsMesh then
            love.graphics.setShader(self.bulletShader)
            self.bulletShader:send("time", timeElapsed)
            self.bulletShader:send("view", Camera.perspective * TransposeMatrix(Camera.transform))
            love.graphics.setMeshCullMode("none")
            love.graphics.draw(BulletsMesh, -self.renderWidth/2, -self.renderHeight/2)
        end

        -- anti alias and overlay
        if ScreenTint > 0.0 then
            love.graphics.setColor(1,0,0)
        else
            love.graphics.setColor(1,1,1)
        end
        love.graphics.setCanvas({self.postProcessingCanvas})
        love.graphics.setShader(self.postProcessingShader)
        self.postProcessingShader:send("xPixelSize", 1 / (520*2))
        self.postProcessingShader:send("yPixelSize", 1 / ((520*9/16)*2))

        local opacity = 1.0
        --if GameState == "level_select" then
        --    opacity = 0.3
        --end
        --if GameState == "countdown" then
        --    opacity = GameCountdownBright
        --    if opacity < 0.3 then
        --        opacity = 0.3
        --    end
        --end
        self.postProcessingShader:send("overlayOpacity", opacity)
        love.graphics.clear(0,0,0,0)
        love.graphics.draw(self.threeCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,-1, self.renderWidth/2, self.renderHeight/2)

        -- motion blur
        love.graphics.setCanvas({self.motionBlurCanvas})
        love.graphics.setShader(self.motionBlurShader)
        self.motionBlurShader:send("oldCanvas", self.motionBlurCanvasOld)
        MotionBlurAmount = 0.0
        --if MotionBlurAmount > MAX_MOTION_BLUR then
        --    MotionBlurAmount = MAX_MOTION_BLUR
        --elseif MotionBlurAmount < 0.0 then
        --    MotionBlurAmount = 0.0
        --end

        self.motionBlurShader:send("amount", MotionBlurAmount)

        love.graphics.clear(0,0,0,0)
        love.graphics.draw(self.postProcessingCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,1, self.renderWidth/2, self.renderHeight/2)

        -- copy motionBlurCanvas into motionBlurCanvasOld for next frame
        love.graphics.setCanvas({self.motionBlurCanvasOld})
        love.graphics.draw(self.motionBlurCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,1, self.renderWidth/2, self.renderHeight/2)
        love.graphics.setCanvas()
        love.graphics.setShader()

        local flip = 1
        --if shouldSwitchScreen() then
        --    flip = -1
        --end

        if drawArg == nil or drawArg == true then
            love.graphics.draw(self.motionBlurCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,flip, self.renderWidth/2-OffsetX, self.renderHeight/2 - OffsetY)
        end
    end

    -- renders the given func to the twoCanvas
    -- this is useful for drawing 2d HUDS and information on the screen in front of the 3d scene
    -- will draw threeCanvas if drawArg is not given or is true (use if you want to scale the game canvas to window)
    scene.renderFunction = function (self, func, drawArg)
        love.graphics.setColor(1,1,1)
        love.graphics.setCanvas(Scene.twoCanvas)
        love.graphics.clear(0,0,0,0)
        func()
        love.graphics.setCanvas()

        local flip = 1
        --if shouldSwitchScreen() then
        --    flip = -1
        --
        
        if drawArg == nil or drawArg == true then
            love.graphics.draw(Scene.twoCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,flip, self.renderWidth/2 - OffsetX, self.renderHeight/2 - OffsetY)
        end
    end

    -- useful if mouse relativeMode is enabled
    -- useful to call from love.mousemoved
    -- a simple first person mouse look function
    scene.mouseLook = function (self, x, y, dx, dy)
        local Camera = engine.camera
        Camera.angle.x = Camera.angle.x + math.rad(dx * 0.5)
        Camera.angle.y = math.max(math.min(Camera.angle.y + math.rad(dy * 0.5), math.pi/2), -1*math.pi/2)
    end

    return scene
end

-- useful functions
function TransposeMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.transpose(m, mat)
end
function InvertMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.invert(m, mat)
end
function CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CopyTable(orig_key)] = CopyTable(orig_value)
        end
        setmetatable(copy, CopyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
function GetSign(n)
    if n > 0 then return 1 end
    if n < 0 then return -1 end
    return 0
end
function CrossProduct(v1,v2)
    local a = {x = v1[1], y = v1[2], z = v1[3]}
    local b = {x = v2[1], y = v2[2], z = v2[3]}

    local x, y, z
    x = a.y * (b.z or 0) - (a.z or 0) * b.y
    y = (a.z or 0) * b.x - a.x * (b.z or 0)
    z = a.x * b.y - a.y * b.x
    return { x, y, z } 
end
function UnitVectorOf(vector)
    local ab1 = math.abs(vector[1])
    local ab2 = math.abs(vector[2])
    local ab3 = math.abs(vector[3])
    local max = VectorLength(ab1, ab2, ab3)
    if max == 0 then max = 1 end

    local ret = {vector[1]/max, vector[2]/max, vector[3]/max}
    return ret
end
function VectorLength(x2,y2,z2) 
    local x1,y1,z1 = 0,0,0
    return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 
end
function ScaleVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]*sx
        this[2] = this[2]*sy
        this[3] = this[3]*sz
    end

    return verts
end
function MoveVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]+sx
        this[2] = this[2]+sy
        this[3] = this[3]+sz
    end

    return verts
end

return engine
