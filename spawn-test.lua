local simulsim = require 'https://raw.githubusercontent.com/bridgs/simulsim/16f08f874610e1da6bd8aaa5401a42555c24c895/simulsim.lua'

local GAME_WIDTH = 279
local GAME_HEIGHT = 145

local syncMode = 'entity.clientId'

local game = simulsim.defineGame()

function game.load(self)
  self.data.numEntitiesSpawnedByGame = 0
  self.data.numEntitiesSpawnedByServer = 0
  self.data.numEntitiesSpawnedByClient = {}
end

function game.update(self, dt)
  -- The game can spawn an entity every so often
  if self.frame % 120 == 0 then
    self:spawnEntity({
      x = 2 + 7 * self.data.numEntitiesSpawnedByGame,
      y = 2
    })
    self.data.numEntitiesSpawnedByGame = self.data.numEntitiesSpawnedByGame + 1
  end
end

function game.handleEvent(self, eventType, eventData)
  if eventType == 'spawn-server-entity' then
    self:spawnEntity({
      x = 2 + 7 * self.data.numEntitiesSpawnedByServer,
      y = 14
    })
    self.data.numEntitiesSpawnedByServer = self.data.numEntitiesSpawnedByServer + 1
  elseif eventType == 'spawn-client-entity' then
    if not self.data.numEntitiesSpawnedByClient[eventData.clientId] then
      self.data.numEntitiesSpawnedByClient[eventData.clientId] = 0
    end
    local entity = self:spawnEntity({
      clientId = eventData.syncMode == 'entity.clientId' and eventData.clientId or nil,
      x = 2 + 7 * self.data.numEntitiesSpawnedByClient[eventData.clientId],
      y = 14 + 12 * eventData.clientId
    })
    if eventData.syncMode == 'temporarilyDisableSync' then
      self:temporarilyDisableSyncForEntity(entity)
    end
    self.data.numEntitiesSpawnedByClient[eventData.clientId] = self.data.numEntitiesSpawnedByClient[eventData.clientId] + 1
  else
  end
end

-- Create a client-server network for the game to run on
local network, server, client = simulsim.createGameNetwork(game, {
  width = 400,
  height = 200,
  numClients = 1,
  latency = 300,
  framesBetweenServerSnapshots = 2
})

function server.load(self)
  self.frame = 0
end
function server.update(self, dt)
  self.frame = self.frame + 1
  if self.frame % 120 == 0 then
    self:fireEvent('spawn-server-entity')
  end
end

function client.load(self)
  self.frame = 0
end
function client.update(self, dt)
  self.frame = self.frame + 1
  if self.frame % 120 == 0 then
    self:fireEvent('spawn-client-entity', { clientId = self.clientId, syncMode = syncMode })
  end
end
function client.draw(self)
  love.graphics.clear(0.1, 0.1, 0.1)
  love.graphics.setColor(1, 1, 1)
  for _, entity in ipairs(self.game.entities) do
    love.graphics.rectangle('fill', entity.x, entity.y, 5, 10)
  end
  self:drawNetworkStats(0, 100, 400, 100)
end

function castle.uiupdate()
  syncMode = castle.ui.dropdown('sync mode', syncMode, { 'entity.clientId', 'temporarilyDisableSync', 'Do nothing (flicker)' })
end
