-- =============================================================================
--  CAMINHOS E COLISÕES
--  O chão vira uma grade. Mesas, balcão e paredes bloqueiam quadradinhos, e cada
--  pessoa calcula a rota desviando deles. Entre as pessoas, quem se aproxima
--  desvia pela direita e, se encostar, é empurrado para o lado.
-- =============================================================================

local Cam = {}

local X0, Z0, S = -7, -5, 0.25
local NX, NZ = 80, 42
local RAIO = 0.3            -- metade da largura de um boneco
Cam.DISTANCIA = 0.62        -- distância mínima entre os centros de dois bonecos

local bloq = {}

local function idx(ix, iz) return iz * NX + ix + 1 end
local function celula(x, z) return math.floor((x - X0) / S), math.floor((z - Z0) / S) end
local function centro(ix, iz) return X0 + (ix + 0.5) * S, Z0 + (iz + 0.5) * S end

-- limites: { xmin, xmax, zmin, zmax }; obstaculos: círculos { x, z, r } ou caixas { id, x, z, ex, ez, base }
function Cam.montar(limites, obstaculos)
  X0, Z0 = math.floor(limites[1]) - 1, math.floor(limites[3]) - 1
  NX = math.ceil((limites[2] + 1 - X0) / S) + 1
  NZ = math.ceil((limites[4] + 1 - Z0) / S) + 1
  bloq = {}
  for iz = 0, NZ - 1 do
    for ix = 0, NX - 1 do
      local x, z = centro(ix, iz)
      bloq[idx(ix, iz)] = x < limites[1] or x > limites[2] or z < limites[3] or z > limites[4]
    end
  end
  -- cada obstáculo só olha os quadradinhos em volta dele: um salão enorme continua rápido
  for i = 1, #obstaculos do
    local o = obstaculos[i]
    local cx, cz, alcance
    if o.r then
      cx, cz, alcance = o.x, o.z, o.r + RAIO
    else
      local ax, az = o.ex / 2 + RAIO, o.ez / 2 + RAIO
      cx, cz = o.mundo(o.id, o.x, o.z)
      alcance = math.sqrt(ax * ax + az * az)
    end
    local i0, k0 = celula(cx - alcance, cz - alcance)
    local i1, k1 = celula(cx + alcance, cz + alcance)
    for iz = math.max(0, k0), math.min(NZ - 1, k1) do
      for ix = math.max(0, i0), math.min(NX - 1, i1) do
        local n = idx(ix, iz)
        if not bloq[n] then
          local x, z = centro(ix, iz)
          if o.r then
            local dx, dz = x - cx, z - cz
            bloq[n] = dx * dx + dz * dz < alcance * alcance
          else
            local bx, bz = o.base(o.id, x, z)
            bloq[n] = math.abs(bx - o.x) < o.ex / 2 + RAIO and math.abs(bz - o.z) < o.ez / 2 + RAIO
          end
        end
      end
    end
  end
end

function Cam.bloqueado(x, z)
  local ix, iz = celula(x, z)
  if ix < 0 or iz < 0 or ix >= NX or iz >= NZ then return true end
  return bloq[idx(ix, iz)] == true
end

-- a volta do início e do destino é sempre liberada: bancos ficam colados nas mesas
local LIVRE2 = 0.36 * 0.36

local function linha_livre(x0, z0, x1, z1, sx, sz, gx, gz)
  local dx, dz = x1 - x0, z1 - z0
  local d = math.sqrt(dx * dx + dz * dz)
  local n = math.max(1, math.ceil(d / 0.1))
  for i = 0, n do
    local x, z = x0 + dx * i / n, z0 + dz * i / n
    if Cam.bloqueado(x, z) then
      local a, b = x - sx, z - sz
      local c, e = x - gx, z - gz
      if a * a + b * b > LIVRE2 and c * c + e * e > LIVRE2 then return false end
    end
  end
  return true
end

-- memória reaproveitada da busca
local custo, veio, marca, geracao = {}, {}, {}, 0
local heap_n, heap_i, heap_f = 0, {}, {}

local function pus(i, f)
  heap_n = heap_n + 1
  local k = heap_n
  while k > 1 do
    local p = k // 2
    if heap_f[p] <= f then break end
    heap_i[k], heap_f[k] = heap_i[p], heap_f[p]
    k = p
  end
  heap_i[k], heap_f[k] = i, f
end

local function pop()
  local topo = heap_i[1]
  local i, f = heap_i[heap_n], heap_f[heap_n]
  heap_n = heap_n - 1
  local k = 1
  while true do
    local c = k * 2
    if c > heap_n then break end
    if c < heap_n and heap_f[c + 1] < heap_f[c] then c = c + 1 end
    if heap_f[c] >= f then break end
    heap_i[k], heap_f[k] = heap_i[c], heap_f[c]
    k = c
  end
  heap_i[k], heap_f[k] = i, f
  return topo
end

local VIZ = { { 1, 0, 1 }, { -1, 0, 1 }, { 0, 1, 1 }, { 0, -1, 1 },
  { 1, 1, 1.414 }, { 1, -1, 1.414 }, { -1, 1, 1.414 }, { -1, -1, 1.414 } }

-- devolve a lista de pontos até o destino, ou nil se não houver como chegar
function Cam.rota(sx, sz, gx, gz)
  if linha_livre(sx, sz, gx, gz, sx, sz, gx, gz) then return { { x = gx, z = gz } } end
  local si, sk = celula(sx, sz)
  local gi, gk = celula(gx, gz)
  si, sk = math.max(0, math.min(NX - 1, si)), math.max(0, math.min(NZ - 1, sk))
  gi, gk = math.max(0, math.min(NX - 1, gi)), math.max(0, math.min(NZ - 1, gk))
  local function livre(ix, iz)
    if not bloq[idx(ix, iz)] then return true end
    local x, z = centro(ix, iz)
    local a, b, c, e = x - sx, z - sz, x - gx, z - gz
    return a * a + b * b < LIVRE2 or c * c + e * e < LIVRE2
  end

  geracao = geracao + 1
  heap_n = 0
  local inicio, fim = idx(si, sk), idx(gi, gk)
  custo[inicio], marca[inicio], veio[inicio] = 0, geracao, nil
  pus(inicio, 0)
  local achou = false
  while heap_n > 0 do
    local at = pop()
    if at == fim then achou = true break end
    local iz = (at - 1) // NX
    local ix = at - 1 - iz * NX
    local base = custo[at]
    for v = 1, 8 do
      local d = VIZ[v]
      local nx, nz = ix + d[1], iz + d[2]
      if nx >= 0 and nz >= 0 and nx < NX and nz < NZ and livre(nx, nz)
        and (d[3] == 1 or (livre(ix + d[1], iz) and livre(ix, iz + d[2]))) then
        local n = idx(nx, nz)
        local c = base + d[3]
        if marca[n] ~= geracao or c < custo[n] then
          marca[n], custo[n], veio[n] = geracao, c, at
          local hx, hz = math.abs(nx - gi), math.abs(nz - gk)
          pus(n, c + (math.max(hx, hz) + 0.414 * math.min(hx, hz)) * 1.001)
        end
      end
    end
  end
  if not achou then return nil end

  local pontos, at = {}, fim
  while at do
    local iz = (at - 1) // NX
    local x, z = centro(at - 1 - iz * NX, iz)
    pontos[#pontos + 1] = { x = x, z = z }
    at = veio[at]
  end
  -- estava do destino para o início
  for a = 1, #pontos // 2 do
    local c = #pontos - a + 1
    pontos[a], pontos[c] = pontos[c], pontos[a]
  end
  pontos[#pontos] = { x = gx, z = gz }

  -- corta os zigue-zagues: vai direto até o ponto mais distante que dá para ver
  local rota, ax, az, i = {}, sx, sz, 1
  while i <= #pontos do
    local j = #pontos
    while j > i and not linha_livre(ax, az, pontos[j].x, pontos[j].z, sx, sz, gx, gz) do j = j - 1 end
    rota[#rota + 1] = pontos[j]
    ax, az = pontos[j].x, pontos[j].z
    i = j + 1
  end
  return rota
end

-- pessoas: lista de objetos com x, z; p.sentado fica parado; p.fantasma ignora colisão
function Cam.separar(pessoas, dt)
  local n = #pessoas
  local R, R2 = Cam.DISTANCIA, Cam.DISTANCIA * Cam.DISTANCIA
  for i = 1, n do
    local p = pessoas[i]
    if not p.fantasma then
      -- quem anda desvia pela direita de quem está à frente
      local a = p.rota and p.rota[1]
      if a and p.andando then
        local dx, dz = a.x - p.x, a.z - p.z
        local d = math.sqrt(dx * dx + dz * dz)
        if d > 0.01 then
          dx, dz = dx / d, dz / d
          for j = 1, n do
            local q = pessoas[j]
            if q ~= p and not q.fantasma then
              local ox, oz = q.x - p.x, q.z - p.z
              local fr = ox * dx + oz * dz
              if fr > 0 and fr < 1.0 and math.abs(ox * dz - oz * dx) < 0.55 then
                local lx, lz = p.x + dz * 1.5 * dt, p.z - dx * 1.5 * dt
                if not Cam.bloqueado(lx, lz) then p.x, p.z = lx, lz end
                break
              end
            end
          end
        end
      end
      for j = i + 1, n do
        local q = pessoas[j]
        if not q.fantasma then
          local dx, dz = q.x - p.x, q.z - p.z
          local d2 = dx * dx + dz * dz
          if d2 < R2 then
            local d = math.sqrt(d2)
            if d < 0.001 then dx, dz, d = 1, 0, 1 else dx, dz = dx / d, dz / d end
            local falta = R - (d2 < 0.000001 and 0 or math.sqrt(d2))
            local pf, qf = p.sentado, q.sentado
            if not (pf and qf) then
              local parte = (pf or qf) and falta or falta / 2
              if not pf then
                local x, z = p.x - dx * parte, p.z - dz * parte
                if not Cam.bloqueado(x, z) or Cam.bloqueado(p.x, p.z) then p.x, p.z = x, z end
              end
              if not qf then
                local x, z = q.x + dx * parte, q.z + dz * parte
                if not Cam.bloqueado(x, z) or Cam.bloqueado(q.x, q.z) then q.x, q.z = x, z end
              end
            end
          end
        end
      end
    end
  end
end

return Cam
