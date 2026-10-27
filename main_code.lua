-- BNXYUNG7 | loader publico | este es el unico archivo que se ejecuta
local ROOT = "https://raw.githubusercontent.com/bnxyung7/External-Roblox/main/.sys/"
local MOD = 1000000007

-- Pines de integridad: si cambia un byte de un modulo, no corre.
local PINS = {
	["rt/session"] = 107350468,
	["core/runtime"] = 207952874,
}

local loaded
pcall(function()
	loaded = getgenv().AIM_LOADED
end)
if loaded == nil then
	loaded = _G.AIM_LOADED
end
if loaded then
	warn("[BNXYUNG7] ya esta cargado en esta sesion.")
	return
end

local function unlock()
	_G.AIM_LOADED = false
	pcall(function()
		getgenv().AIM_LOADED = false
	end)
end

local function allow()
	_G.AIM_LOADED = true
	pcall(function()
		getgenv().AIM_LOADED = true
	end)
end

local function hash(str)
	local h = 5381
	for index = 1, #str do
		h = (h * 33 + str:byte(index)) % MOD
	end
	return h
end

local function fetch(name)
	local ok, body = pcall(function()
		return game:HttpGet(ROOT .. name .. ".lua", true)
	end)
	if not ok or type(body) ~= "string" or #body == 0 then
		return nil, "no se pudo descargar " .. name .. " (la URL no responde)"
	end
	if body:find("<!DOCTYPE") or body:find("404: Not Found") then
		return nil, "GitHub devolvio una pagina de error: cambio la ruta o el repo volvio a ser privado"
	end
	if hash(body) ~= PINS[name] then
		return nil, "checksum distinto en " .. name .. ": el archivo fue modificado y no se ejecuta"
	end
	local chunk = loadstring(body)
	if not chunk then
		return nil, name .. " no compilo"
	end
	return chunk
end

local sessionChunk, sessionError = fetch("rt/session")
if not sessionChunk then
	unlock()
	warn("[BNXYUNG7] " .. sessionError)
	return
end
local meta = sessionChunk()

local runtimeChunk, runtimeError = fetch("core/runtime")
if not runtimeChunk then
	unlock()
	warn("[BNXYUNG7] " .. runtimeError)
	return
end

allow()
local ran, runtimeCrash = pcall(runtimeChunk)
if not ran then
	unlock()
	error("[BNXYUNG7] error en el modulo principal: " .. tostring(runtimeCrash))
end

print(("[BNXYUNG7] v%s (%s) | %d modulos verificados"):format(meta.version, meta.channel, #meta.modules))
