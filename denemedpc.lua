local mem = ac.storage({
	pos = vec3(0, 0, 0),
	dir = vec3(0, 0, 0),
	vel = vec3(0, 0, 0),
	gear = 0,
	rpm = 0,
	extraspeeder = 1,
	extraspeedermouse = 1,
	aicheckbox = false,
	aiLevel = 0.5,
	aiAgression = 0.5,
	keybindtext = " ",
})

local function savepos1()
	local car = ac.getCar(0)
	mem.pos = car.position
	mem.dir = car.look
	mem.vel = car.velocity
	mem.gear = car.gear
	mem.rpm = car.rpm
end

local function loadpos1()
	physics.setCarPosition(0, mem.pos, -mem.dir)
	physics.setCarVelocity(0, mem.vel:mul(vec3(mem.extraspeeder, mem.extraspeeder * 0.8, mem.extraspeeder)))
	physics.setEngineRPM(0, mem.rpm)
	if mem.extraspeeder <= 1 then
		physics.engageGear(0, mem.gear)
	else
		if mem.extraspeeder > 1 then
			physics.engageGear(0, ac.getCar(0).gearCount)
		end
	end
end

local function TeleportCam()
	local tp = ac.getCameraPosition()
	local dir = ac.getCameraForward()
	physics.setCarPosition(0, tp + dir * 5, -dir)
	physics.setCarVelocity(0, dir:mul(vec3(mem.extraspeedermouse, mem.extraspeedermouse, mem.extraspeedermouse)))
end

local function tab2()
	if ui.button("Konumu Kayet") then
		savepos1()
		mem.keybindtext = "Kaydedildi"
	end
	ui.sameLine()
	if ui.button("Konum Yükle") then
		loadpos1()
		mem.keybindtext = "Yüklendi"
	end

	local extraspeed = ui.slider("##" .. "Hız", mem.extraspeeder, 0, 1, "Hız Koruması" .. ": %.1f")
	if extraspeed then
		mem.extraspeeder = extraspeed
	end
	if ui.checkbox("Tuş Ata", keybinder) then
		keybinder = not keybinder
	end

	if keybinder == true then
		ui.sameLine()
		ui.text("Sol Yön Tuşu Kayıt Eder\nSağ Yön Tuşu Yükler")
	end
	if keybinder == true and ui.keyPressed(ui.Key.Left) then
		savepos1()
		mem.keybindtext = "Kaydedildi"
	end
	if keybinder == true and ui.keyPressed(ui.Key.Right) then
		loadpos1()
		mem.keybindtext = "Yüklendi"
	end
	ui.text("Son Durum: " .. mem.keybindtext)
end

--#region [Map stuff, experimental bad]
local mapstuff = {}
local pos3, dir3, pos2, dir2, dir2x = vec3(), vec3(), vec2(), vec2(), vec2()
local padding = vec2(30*3, 50*3)
local offsets = -padding * 0.5
local ts = 10
local first = true

if ac.getPatchVersionCode() >= 2000 then
	map = ac.getFolder(ac.FolderID.ContentTracks) .. '/' .. ac.getTrackFullID('/') .. '/map.png'
	current_map = map
	ui.decodeImage(map)

	--ini stuff size
	ini = ac.getFolder(ac.FolderID.ContentTracks) .. "/" .. ac.getTrackFullID("/") .. "/data/map.ini"
	for a, b in ac.INIConfig.load(ini):serialize():gmatch("([_%a]+)=([-%d.]+)") do -- ◀ i dont understand the "([_%a]+)=([-%d.]+)"
		mapstuff[a] = tonumber(b)
	end
	image_size = ui.imageSize(map)
	config_offset = vec2(mapstuff.X_OFFSET, mapstuff.Z_OFFSET)
end

function MapTest()
	ui.text([[
Press Spacebar while on map to teleport the Camera | You can Drag and zoom into the map. (zoom completely out of it bugged)
Green = Camera/You
Red = other users.]])
	ui.childWindow("##mapforcamera", vec2(ui.availableSpaceX(), ui.availableSpaceY()),
	function()
		if ac.getPatchVersionCode() < 2000 then ui.text("only above ver 2000 it work") return end

		if first then --set the map scale, if not in here it will keep the size and not scale with scroll wheel
			map_scale = math.min((ui.windowWidth() - padding.x) / image_size.x, (ui.windowHeight() - padding.y) / image_size.y)
			config_scale = map_scale / mapstuff.SCALE_FACTOR
			size = image_size * map_scale
			if ui.isImageReady(current_map) then
				first = false
			end
		end

		ui.drawImage(current_map, -offsets, -offsets + size)

		if ui.windowHovered() then --zoom&drag
			if ac.getUI().mouseWheel ~= 0 then
			  if 
			  (	ac.getUI().mouseWheel < 0 and (size.x + padding.x > ui.windowWidth() and size.y + padding.y > ui.windowHeight())) 
				or ac.getUI().mouseWheel > 0 then
				local old = size
				map_scale = map_scale * (1 + ac.getUI().mouseWheel * 0.15)
				size = ui.imageSize(current_map) * map_scale
				config_scale = map_scale / mapstuff.SCALE_FACTOR
				offsets = (offsets + (size - old) * (offsets + ui.mouseLocalPos()) / old)
			  else
				offsets = -padding * 0.5
				map_scale = math.min((ui.windowWidth() - padding.x) / image_size.x,(ui.windowHeight() - padding.y) / image_size.y)
				size = ui.imageSize(current_map) * map_scale
				config_scale = map_scale / mapstuff.SCALE_FACTOR
			  end
			end
		  end

		--other ppl pos
		for i = ac.getSim().carsCount - 1, 1, -1 do --draw stuff on map
			local car = ac.getCar(i)
			if car.isConnected and (not car.isHidingLabels) then
				local pos3 = car.position
				local dir3 = car.look

				pos2:set(pos3.x, pos3.z):add(config_offset):scale(config_scale):add(-offsets)
				dir2:set(dir3.x, dir3.z) -- = vec2(dir3.x, dir3.z)
				dir2x:set(dir3.z, -dir3.x)
				ui.drawTriangleFilled(
					pos2 + dir2 * ts,
					pos2 - dir2 * ts - dir2x * ts * 0.75,
					pos2 - dir2 * ts + dir2x * ts * 0.75,
					rgbm(255,0,0,255))
				ui.dwriteDrawText(ac.getDriverName(i),10,pos2 + vec2(25,5) - ui.measureText(ac.getDriverName(i)) * 0.5,rgbm.colors.	white)
			end
		end

		--camera pos and local user 
		pos3 = ac.getCameraPosition()
		pos2:set(pos3.x, pos3.z):add(config_offset):scale(config_scale):add(-offsets)
		dir3 = ac.getCameraForward()
		dir2 = vec2(dir3.x, dir3.z):normalize()
		dir2x:set(dir3.z, -dir3.x):normalize()
		ui.drawTriangleFilled(
			pos2 + dir2 * ts,
			pos2 - dir2 * ts - dir2x * ts * 0.75,
			pos2 - dir2 * ts + dir2x * ts * 0.75,
			rgbm(0, 255, 0, 255))
		if ui.keyPressed(ui.Key.Space) and ui.windowHovered() then
			local camerapos = (ui.mouseLocalPos() + offsets) / config_scale - config_offset
			local raycast = physics.raycastTrack(vec3(camerapos.x, 2000, camerapos.y), vec3(0, -1, 0), 3000)
			local cameraheight = 2000 - raycast + 3
			if raycast ~= -1 then
				ac.setCurrentCamera(ac.CameraMode.Free)
				ac.setCameraPosition(vec3(camerapos.x, cameraheight, camerapos.y))
			end
		end

		ui.invisibleButton('###mapforcamera4242', ui.windowSize())
		if ui.mouseDown() and ui.itemHovered() then offsets = offsets - ui.mouseDelta() end
	end)
end

--endregion

local function RDMBULLSHITHud()
	ui.tabBar("sabcar", function()
		ui.tabItem("Kayıt", tab2)
		ui.tabItem("Map", MapTest)	
	end)
end
ui.registerOnlineExtra(ui.Icons.Save, "DPC HIZLI SAVE", nil, RDMBULLSHITHud, nil, ui.OnlineExtraFlags.Tool)
