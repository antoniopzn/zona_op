# Zona de Operação Policial - FiveM (vRPex)

Este script cria uma **zona de operação policial** no mapa do FiveM, permitindo que policiais iniciem uma área visível (blip no mapa/minimapa) com raio configurável.  
Jogadores pertencentes a grupos **ilegais** que entrarem nesta área recebem um **alerta de risco**, simulando operações policiais em andamento.

---

## 🚀 Funcionalidades

- **Ativação manual por comando** (`/zonaop`) apenas para policiais (`perm.policia`).
- **Também é possível habilitar pelo comando (`/zonaop [tempo] [raio]`).
- **É possível o policial desabilitar a área estando dentro dela com o comando (`/zonaopoff`).
- **Área visível no mapa/minimapa** com:
  - Círculo de raio configurável.
  - Ícone central com texto personalizado.
- **Notificação automática** para jogadores ilegais (`perm.ilegal`) ao entrarem na área.
- Compatível com **vRPex**.
- Configurações de cor, ícone e opacidade ajustáveis via `config.lua`.

---

## 📋 Requisitos

- **FiveM** (testado na build 3258)
- **Framework vRPex** (versão)
- Permissões configuradas no `permissions.cfg`:
  ```ini
  add_ace group.policia perm.policia allow
  add_ace group.ilegal perm.ilegal allow
