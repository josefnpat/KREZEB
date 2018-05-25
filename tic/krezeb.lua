-- title:  krezeb
-- author: @josefnpat
-- desc:   GWC2?
-- script: lua

-- SUPPORT FUNCTIONS

function is_sprite(value,sprites)
  for _,sprite in pairs(sprites) do
    if sprite == value then
      return true
    end
  end
  return false
end

function move_object(object,x,y,dir)
  local tx,ty = object.x+x,object.y+y
  local tile = mget(tx/8+0.5,ty/8+0.5)
  if is_sprite(tile,SPRITE_EMPTY) then
    object.x,object.y = tx,ty
  end
  if dir then
    object.dir = dir
  end
  return tile
end

function distance(a,b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end

function collide(a,b,td)
  return distance(a,b) < td
end

_dirs={{0,-1},{0,1},{-1,0},{1,0}}
function dir_to_vec(dir)
  local vec = _dirs[dir+1]
  return vec[1],vec[2]
end

function move_towards(a,b)
  local tx,ty = 0,0
  if distance(a,b) < 64 then
    if a.x < b.x then tx = 1 end
    if a.x > b.x then tx = -1 end
    if a.y < b.y then ty = 1 end
    if a.y > b.y then ty = -1 end
  end
  return tx,ty
end

-- SETUP

SPRITE_PLAYER = 1
SPRITE_BULLET = 2
SPRITE_EMPTY = {0,53}
SPRITE_MONSTER = {3,4,5}

WIDTH=240
HEIGHT=136

bullets = {}
player = {dir = 0}
monsters = {}
for x = 1,WIDTH do
  for y = 1,HEIGHT do
    local sprite = mget(x,y)
    if sprite == SPRITE_PLAYER then
      player.x,player.y = x*8,y*8
      mset(x,y,0)
    elseif is_sprite(sprite,SPRITE_MONSTER) then
      table.insert(monsters,{x=x*8,y=y*8,spr=sprite})
      mset(x,y,0)
    end
  end
end

-- MAIN FUNCTION

function TIC()
  cls()
  local ox = WIDTH/2-player.x
  local oy = HEIGHT/2-player.y

  -- MAP

  map(0,0,WIDTH,HEIGHT,ox,oy)

  -- PLAYER

  spr(SPRITE_PLAYER,player.x+ox,player.y+oy,0)
  if not player.dead then
    local tx,ty = 0,0
    if btn(0) then move_object(player,0,-1,0) end
    if btn(1) then move_object(player,0,1,1) end
    if btn(2) then move_object(player,-1,0,2) end
    if btn(3) then move_object(player,1,0,3) end
    if btnp(4) then
      table.insert(bullets,{x=player.x,y=player.y,dir=player.dir})
    end
  end

  -- MONSTERS

  for _,monster in pairs(monsters) do
    spr(monster.spr,monster.x+ox,monster.y+oy,0)
    local tx,ty = move_towards(monster,player)
    move_object(monster,0,ty/4)
    move_object(monster,tx/4,0)
    if collide(monster,player,4) then
      player.dead = true
    end
  end

  -- BULLETS

  for ibullet,bullet in pairs(bullets) do
    spr(SPRITE_BULLET,bullet.x+ox,bullet.y+oy,0)
    local tx,ty = dir_to_vec(bullet.dir)
    local tile = move_object(bullet,tx*2,ty*2)
    if is_sprite(tile,SPRITE_EMPTY) then
      for imonster,monster in pairs(monsters) do
        if collide(bullet,monster,8) then
          table.remove(bullets,ibullet)
          table.remove(monsters,imonster)
        end
      end
    else
      table.remove(bullets,ibullet)
    end
  end

  -- GUI

  if player.dead then
    print("YOU LOSE")
  elseif #monsters == 0 then
    print("YOU WIN")
  end

end
