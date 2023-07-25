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

	local extraspeed = ui.slider("##" .. "Speed", mem.extraspeeder, 0, 10, "Speed Multiplyer" .. ": %.1f")
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

	if ui.checkbox("TP to Cam", keybindermouse) then
		keybindermouse = not keybindermouse
	end
	if keybindermouse == true and ui.keyPressed(ui.Key.Insert) then
		TeleportCam()
		mem.keybindtext = "TP to Cam"
	end
	if keybindermouse == true then
		local extraspeedmouse = ui.slider(
			"##" .. "unique",
			mem.extraspeedermouse,
			0,
			1000,
			"Speed: %.0fm/s: " .. mem.extraspeedermouse * 3.6 .. "Kmh",
			2
		)
		if extraspeedmouse then
			mem.extraspeedermouse = extraspeedmouse
		end
	end
	ui.text("last interaction: " .. mem.keybindtext)
end


local function RDMBULLSHITHud()
	ui.tabBar("sabcar", function()
		ui.tabItem("Kayıt", tab2)
	end)
end
ui.registerOnlineExtra(ui.Icons.Crosshair, "DPC HIZLI SAVE", nil, RDMBULLSHITHud, nil, ui.OnlineExtraFlags.Tool)
