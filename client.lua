-- client puro (sem module/Tunnel/Proxy). Nunca use os.* aqui.

local zone = nil
local blipRadius, blipCenter = nil, nil
local endTime = 0

local function dbg(...)
  if Config and Config.Debug then
    print("[ZONA_OP][CLIENT]", ...)
  end
end

-- servidor pede posição do PM (pra criar a zona)
RegisterNetEvent("zona_op:requestPos")
AddEventHandler("zona_op:requestPos", function(duration, radius)
  local ped = PlayerPedId()
  local x, y, z = table.unpack(GetEntityCoords(ped))
  TriggerServerEvent("zona_op:reportPos", x, y, z, duration, radius)
  dbg("reportPos enviado", x, y, z, duration, radius)
end)

local function removeBlips()
  if blipRadius then RemoveBlip(blipRadius) blipRadius = nil end
  if blipCenter then RemoveBlip(blipCenter) blipCenter = nil end
end

local function createBlips(x,y,z,radius)
  removeBlips()

  -- Blip de raio (círculo)
  blipRadius = AddBlipForRadius(x + 0.0, y + 0.0, z + 0.0, radius + 0.0)
  SetBlipHighDetail(blipRadius, true)
  SetBlipColour(blipRadius, Config.BlipColor or 1)
  SetBlipAlpha(blipRadius, Config.BlipAlpha or 160) -- >= 120 garante visibilidade
  SetBlipDisplay(blipRadius, 2)                      -- mapa+minimapa
  SetBlipAsShortRange(blipRadius, false)

  -- Blip central (ícone alvo)
  blipCenter = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)
  SetBlipSprite(blipCenter, Config.CenterIcon or 60)
  SetBlipColour(blipCenter, Config.BlipColor or 1)
  SetBlipScale(blipCenter, Config.CenterScale or 0.9)
  SetBlipDisplay(blipCenter, 2)
  SetBlipAsShortRange(blipCenter, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Zona de Operação Policial")
  EndTextCommandSetBlipName(blipCenter)

  dbg("Blips criados")
end

-- recebe sync do servidor com timeLeftMs (sem usar os.* no client)
RegisterNetEvent("zona_op:syncZone")
AddEventHandler("zona_op:syncZone", function(data)
  -- data = { x, y, z, radius, timeLeftMs }
  zone = { x = data.x + 0.0, y = data.y + 0.0, z = data.z + 0.0, radius = data.radius + 0.0 }
  local msLeft = tonumber(data.timeLeftMs or 0)
  if not msLeft or msLeft < 0 then msLeft = 0 end
  endTime = GetGameTimer() + msLeft
  createBlips(zone.x, zone.y, zone.z, zone.radius)
  dbg("syncZone recebida; msLeft=", msLeft)
end)

RegisterNetEvent("zona_op:clearZone")
AddEventHandler("zona_op:clearZone", function()
  zone = nil
  removeBlips()
  dbg("clearZone recebido")
end)

RegisterNetEvent("zona_op:illegalAlert")
AddEventHandler("zona_op:illegalAlert", function(msg)
  local text = msg or "Atenção!"
  TriggerEvent("chat:addMessage", { args = { "[ALERTA POLICIAL]", text } })
end)

-- LOOP: verifica se o jogador está dentro do raio e avisa o servidor (mesmo sem marker)
CreateThread(function()
  local lastCheck = 0
  while true do
    if zone then
      Wait(0)

      -- tempo esgotado? limpa localmente
      if GetGameTimer() > endTime then
        zone = nil
        removeBlips()
      else
        -- a cada 1000 ms, faz a checagem de entrada no raio
        local now = GetGameTimer()
        if now - lastCheck > 1000 then
          lastCheck = now
          local ped = PlayerPedId()
          local px,py,pz = table.unpack(GetEntityCoords(ped))
          local dist = #(vector3(px,py,pz) - vector3(zone.x, zone.y, zone.z))
          if dist <= (zone.radius + 0.01) then
            TriggerServerEvent("zona_op:checkInside", px,py,pz)
          end
        end
      end
    else
      Wait(500)
    end
  end
end)
