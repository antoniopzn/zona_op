local Tunnel = module("vrp","lib/Tunnel")
local Proxy  = module("vrp","lib/Proxy")
vRP       = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

local currentZone = nil
local lastAlertAt = {}   -- [user_id] = os.time()
local lastCreateAt = {}  -- [user_id] = os.time()

-- helpers
local function hasAnyPermission(user_id, perms)
  if not user_id then return false end
  for _,p in ipairs(perms or {}) do
    if vRP.hasPermission(user_id, p) then return true end
  end
  return false
end

local function isIllegal(user_id)
  if not user_id then return false end
  if Config.IllegalPermission and vRP.hasPermission(user_id, Config.IllegalPermission) then
    return true
  end
  for _,grp in ipairs(Config.IllegalGroups or {}) do
    if vRP.hasGroup(user_id, grp) then return true end
  end
  return false
end

local function sendMsg(src, title, msg, typ)
  if Config.UseChatFallback then
    TriggerClientEvent("chat:addMessage", src, { args = { title or "[ZONA OP]", msg or "" } })
  else
    TriggerClientEvent("Notify", src, typ or "aviso", msg or "")
  end
end

local function broadcast(msg)
  TriggerClientEvent("chat:addMessage", -1, { args = { "[ZONA OP]", msg } })
end

local function debugPrint(...)
  if Config.Debug then print("[ZONA_OP]", ...) end
end

-- envia a zona com timeLeftMs calculado no servidor (client não usa os.*)
local function emitSync(target)
  if not currentZone then
    TriggerClientEvent("zona_op:clearZone", target)
    return
  end
  local timeLeftMs = math.max(0, (currentZone.expires - os.time()) * 1000)
  TriggerClientEvent("zona_op:syncZone", target, {
    x = currentZone.x, y = currentZone.y, z = currentZone.z,
    radius = currentZone.radius,
    timeLeftMs = timeLeftMs
  })
end

-- sincroniza pro spawn
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
  if source then emitSync(source) end
end)

-- /zonaop [tempo] [raio]
RegisterCommand("zonaop", function(source, args)
  local user_id = vRP.getUserId(source)
  if not user_id then return end

  if not hasAnyPermission(user_id, Config.PolicePermissions) then
    sendMsg(source, "[ZONA OP]", "Você não tem permissão para usar este comando.", "negado")
    return
  end

  -- cooldown por policial
  local now = os.time()
  local cd = Config.PoliceCooldown or 0
  if cd > 0 and (lastCreateAt[user_id] or 0) + cd > now then
    local faltam = (lastCreateAt[user_id] + cd) - now
    sendMsg(source, "[ZONA OP]", ("Aguarde %ds para criar outra zona."):format(faltam), "negado")
    return
  end

  -- parse args
  local duration = tonumber(args[1]) or Config.ZoneDuration
  local radius   = tonumber(args[2]) or Config.ZoneRadius
  if duration < 10 then duration = 10 end
  if radius   < 20 then radius   = 20 end

  -- peça a posição ao client (evita falha de getPosition em algumas bases)
  TriggerClientEvent("zona_op:requestPos", source, duration, radius)
  debugPrint("Solicitada posição ao client", user_id, "dur=", duration, "rad=", radius)
end)

-- recebe do client a posição do policial
RegisterNetEvent("zona_op:reportPos")
AddEventHandler("zona_op:reportPos", function(x,y,z,duration,radius)
  local src = source
  local user_id = vRP.getUserId(src)
  if not user_id then return end
  if not hasAnyPermission(user_id, Config.PolicePermissions) then return end

  local now = os.time()
  currentZone = {
    x = x + 0.0, y = y + 0.0, z = z + 0.0,
    radius = radius,
    expires = now + duration
  }
  lastCreateAt[user_id] = now

  -- sincroniza com todos já com timeLeftMs
  emitSync(-1)
  sendMsg(src, "[ZONA OP]", ("Zona criada por %ds (raio %.0fm)."):format(duration, radius), "sucesso")
  broadcast(("Uma zona de operação policial foi ativada! (%ds, raio %.0fm)"):format(duration, radius))
  debugPrint("Zona criada em", x, y, z, "dur=", duration, "rad=", radius)

  SetTimeout(duration * 1000, function()
    if currentZone and os.time() >= currentZone.expires then
      currentZone = nil
      TriggerClientEvent("zona_op:clearZone", -1)
      broadcast("A zona de operação policial foi encerrada.")
      debugPrint("Zona expirada e limpa")
    end
  end)
end)

-- /zonaopoff
RegisterCommand("zonaopoff", function(source)
  local user_id = vRP.getUserId(source)
  if not user_id then return end
  if not hasAnyPermission(user_id, Config.PolicePermissions) then
    sendMsg(source, "[ZONA OP]", "Você não tem permissão para usar este comando.", "negado")
    return
  end

  if currentZone then
    currentZone = nil
    TriggerClientEvent("zona_op:clearZone", -1)
    broadcast("A zona de operação policial foi encerrada manualmente.")
    debugPrint("Zona encerrada manualmente por", user_id)
  else
    sendMsg(source, "[ZONA OP]", "Não há zona ativa.", "aviso")
  end
end)

-- valida entrada (client envia coords, server confirma e alerta ilegais)
RegisterNetEvent("zona_op:checkInside")
AddEventHandler("zona_op:checkInside", function(px,py,pz)
  local src = source
  local user_id = vRP.getUserId(src)
  if not user_id or not currentZone then return end
  local now = os.time()
  if now >= (currentZone.expires or 0) then return end

  local dx = (px - currentZone.x)
  local dy = (py - currentZone.y)
  local dz = (pz - currentZone.z)
  local dist2 = dx*dx + dy*dy + dz*dz
  if dist2 > (currentZone.radius * currentZone.radius) then return end

  if isIllegal(user_id) then
    local last = lastAlertAt[user_id] or 0
    if now - last >= (Config.AlertCooldown or 10) then
      lastAlertAt[user_id] = now
      TriggerClientEvent("zona_op:illegalAlert", src, Config.AlertText or "Você entrou em uma zona de operação da polícia!")
      debugPrint("Alerta enviado a ilegal", user_id)
    end
  end
end)
