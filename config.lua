Config = {}

-- QUEM PODE USAR /zonaop
Config.PolicePermissions = {
  "perm.policia"
}

-- COOLDOWN por policial (s)
Config.PoliceCooldown = 60

-- DURAÇÃO e RAIO padrão (podem ser sobrescritos por: /zonaop [tempo] [raio])
Config.ZoneDuration = 300   -- segundos
Config.ZoneRadius   = 100.0 -- metros

-- QUEM É ILEGAL (recebe alerta ao entrar)
Config.IllegalPermission = "perm.ilegal"  -- padrão FOXZIN
Config.IllegalGroups = {                   -- opcional (deixe vazio se não usar grupos)
  -- "traficante","milicia","mafia","cv","tcp"
}

-- Anti-spam de alerta (s)
Config.AlertCooldown = 30

-- Visual (blips/marker)
Config.BlipColor   = 1   -- vermelho
Config.BlipAlpha   = 160 -- >=120 melhora visibilidade
Config.CenterIcon  = 60  -- alvo
Config.CenterScale = 0.9

-- Texto do alerta
Config.AlertText = "Você entrou em uma zona de operação da polícia! Evite atividades ilegais."

-- Se não usar Notify, cai pro chat
Config.UseChatFallback = true

-- Debug no console
Config.Debug = true
