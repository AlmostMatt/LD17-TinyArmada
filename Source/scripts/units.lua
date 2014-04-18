--units

COLONY = 0
CAPITAL = 1
GALLEY = 2
MERCHANT = 3

function isboat(t)
	return t > 1
end

maxhp={
	[GALLEY]		= 30,
	[CAPITAL]		= 150,
	[MERCHANT]	= 25,
	[COLONY]		= 70,
}

speed={
	[GALLEY]		= 25,
	[MERCHANT]	= 35,
}

size={
	[GALLEY]		= gu*0.5,
	[MERCHANT]	= gu*0.4,
	[COLONY]	= gu*0.6,
	[CAPITAL]	= gu*1.0,
}

cost={
	[GALLEY]		= 100,
	[MERCHANT]	= 50,
}

healradius={
	[CAPITAL] = 80,
	[COLONY] = 60,
}

healpower={ --ammount that it heals others and itself in one second
	[CAPITAL] = 5,
	[COLONY] = 3,
}

range={
	[GALLEY] = 80,
	[MERCHANT] = 100,
}

--team
numplayers=4

colors = {
	[0]={128,128,128},
	{0,0,255},
	{255,0,0},
	{255,255,255},
	{0,0,0},
}


function spawn(x,y,t,angle,team)
	table.insert(units,{x=x,y=y,t=t,hp=maxhp[t],vx=0,vy=0,cooldown=0,gold=0,angle=angle,team=team})
end

function distance(x1,y1,x2,y2)
	return (x2-x1)^2+(y2-y1)^2
end

function unitstuff(dt)
	--ripples
	if frame >= 10 then
		frame = 0
		for i,u in ipairs(units) do
			if isboat(u.t) and (u.vx~=0 or u.vy~=0) then
				table.insert(ripples,{x=u.x,y=u.y,t=80,ti=80,s=30})
			end
		end
	else
		frame = frame+1
	end
	--burning
	if frame2 >= 1 then
		frame2 = 0
		for i,u in ipairs(units) do
			local hurt = 1-u.hp/maxhp[u.t]
			if hurt>0 then
				burn(u.x,u.y,size[u.t]*hurt)
			end
		end
	else
		frame2 = frame2+1
	end
	--slow heal when near friendly structures
	for i,u in ipairs(units) do
		if healradius[u.t] then
			u.hp = math.min(maxhp[u.t],u.hp + healpower[u.t]*dt)
			for i2,u2 in ipairs(units) do
				if i2 ~= i1 and u.team == u2.team and not healradius[u2.t] then
					if distance(u.x,u.y,u2.x,u2.y) < healradius[u.t]^2 then
						u2.hp = math.min(maxhp[u2.t],u2.hp + healpower[u.t]*dt)
					end
				end
			end
		end
	end
	
	
	
	--moving units
	for i,u in ipairs(units) do
		if isboat(u.t) then
			local maxforce = 100
			if u.path then
				--seek current part of path, arrival last part of path
				local x2,y2 = unpack(u.path[1])
				local dx,dy = x2-u.x,y2-u.y
				local d = math.sqrt(dx*dx+dy*dy)
				if d < gu/2 then
					table.remove(u.path,1)
					if #u.path == 0 then
					u.path = nil
					u.vx=0
					u.vy=0
						if u.loading then
							u.loading = false
							--	local dd = distance(u.x,u.y,u.tradewith.x,u.tradewith.y)
							--just reached colony
							local amount = math.min( math.floor(u.tradewith.gold) , 25-u.gold )
							u.tradewith.gold = math.max(u.tradewith.gold - amount, 0.02)
							u.gold = u.gold + amount
							local capital = player[u.team].capitals[1]
							local mindd = distance(u.x,u.y,capital.x,capital.y)
							for i2 = 2,#player[u.team].capitals do
								local c = player[u.team].capitals[i2]
								local dd = distance(u.x,u.y,c.x,c.y)
								if dd < mindd then
									mindd = dd
									capital = c
								end
							end
							u.dropoff = true
							u.path=findpath(u.x,u.y,capital.dock.x,capital.dock.y)
						elseif u.dropoff then
							u.dropoff = false
							--just reached base
							player[u.team].gold=player[u.team].gold+u.gold
							u.gold = 0
							if u.tradewith.t == COLONY then
								u.path=findpath(u.x,u.y,u.tradewith.dock.x,u.tradewith.dock.y)
								u.loading = true
							end
						end
					end
				else
					local s = speed[u.t]/d
					local vx2,vy2 = dx*s,dy*s
					local fx,fy = vx2-u.vx,vy2-u.vy
					local f = math.sqrt(fx*fx+fy*fy)
					if f > 0 then
						s = maxforce/f
						fx,fy = fx*s,fy*s
						u.vx=u.vx+fx*dt
						u.vy=u.vy+fy*dt
					end
					u.x=u.x+u.vx*dt
					u.y=u.y+u.vy*dt
					if u.vx~=0 or u.vy~= 0 then
						u.angle = math.atan2(u.vy,u.vx)
					end
				end
			end
		end
		--shoot stuff
		if u.t == GALLEY then
			local mindd,minu = 100^2,nil
			--local nearenemies = {}
			for i2,u2 in ipairs(units) do
				if u2.team~=u.team then
					local dx,dy = u2.x-u.x,u2.y-u.y
					local dd = dx*dx+dy*dy
					if dd<mindd then mindd,minu = dd,u2 end --table.insert(nearenemies,u2) end
				end
			end
			if u.cooldown > 0 then u.cooldown = u.cooldown - 1 end
			--if #nearenemies > 0 then
			--	local minu = nearenemies[math.random(1,#nearenemies)]
			if minu then
				if u.cooldown == 0 then
					local shotspeed = 150
					local t = math.sqrt(mindd)/shotspeed --time for a shot to reach the target
					local x1,y1 = u.x+math.random(-5,5),u.y+math.random(-5,5)
					local x2,y2 = minu.x+minu.vx*t+math.random(-5,5),minu.y+minu.vy*t+math.random(-5,5) 
					local dx,dy = x2-x1,y2-y1
					local s = math.sqrt(dx*dx+dy*dy)
					local vx,vy = dx*shotspeed/s,dy*shotspeed/s
					table.insert(shots,{x=x1,y=y1,z=1,vx=vx,vy=vy,vz=40,shooter=u})
					u.cooldown = 5
				end
			end
		end
	end
	
	--gold making
	for i,u in ipairs(units) do
		if u.t == COLONY then
			u.gold=math.min(25,u.gold+0.02)
		end
	end
	--[[
	for i,u in ipairs(units) do
		if not u.path then
			for i2,u2 in ipairs(units) do
				if i2~= i then
					local d = math.sqrt(distance(u.x,u.y,u2.x,u2.y))
					local dx,dy = u.x-u2.x,u.y-u2.y
					local s = (size[u2.t]+size[u.t])/d
					if d < size[u.t]+size[u2.t] then
						u.path = findpath(u.x,u.y,u2.x+dx*s,u2.y+dy*s)
						break
					end
				end
			end
		end
	end
	]]
	
end

function showselected()
	--draw selection visualization
	for i,u in ipairs(hover) do
		love.graphics.setColor(255,255,255,255)
		love.graphics.circle('line',u.x,u.y,size[u.t]*1.6,24)
	end
	if #selection>0 then
		for i,u in ipairs(selection) do
			love.graphics.setColor(255,255,255,255)
			love.graphics.circle('line',u.x,u.y,size[u.t]*1.5,24)
		end
	end
end

function drawpaths()
	--path that is being drawn
	love.graphics.setColor(0,0,0)
	if path then
		local lx,ly = unpack(path[1])
		for i = 2,#path do
			local x,y = unpack(path[i])
			love.graphics.line(lx,ly,x,y)
			lx,ly = x,y
		end
		love.graphics.line(lx,ly,mx,my)
	end
	--unit paths
	love.graphics.setColor(0,0,0,128)
	for i,u in ipairs(units) do
		if u.team == 1 then
			local lx,ly = u.x,u.y
			if u.path then
				for i = 1,#u.path do
					local x,y = unpack(u.path[i])
					love.graphics.line(lx,ly,x,y)
					lx,ly = x,y
				end
			end
		end
	end
end

function drawunits()
	--draw units
	for i,u in ipairs(units) do
		if u.t == COLONY then
			love.graphics.setColor(255,255,255)
			love.graphics.draw(images.dock,u.dock.x,u.dock.y,u.dock.angle,1,1,16,16)
			love.graphics.draw(images.colony,u.x-16,u.y-16)
			love.graphics.setColor(unpack(colors[u.team]))
			love.graphics.draw(coloring.colony,u.x-16,u.y-16)
		elseif u.t == CAPITAL then
			love.graphics.setColor(255,255,255)
			love.graphics.draw(images.dock,u.dock.x,u.dock.y,u.dock.angle,1,1,16,16)
			love.graphics.draw(images.capital,u.x-32,u.y-32)
			love.graphics.setColor(unpack(colors[u.team]))
			love.graphics.draw(coloring.capital,u.x-32,u.y-32)
		elseif u.t == GALLEY then
			love.graphics.setColor(255,255,255)
			love.graphics.draw(images.galley,u.x,u.y,u.angle,1,1,16,16)
			love.graphics.setColor(unpack(colors[u.team]))
			love.graphics.draw(coloring.galley,u.x,u.y,u.angle,1,1,16,16)
		elseif u.t == MERCHANT then
			love.graphics.setColor(255,255,255)
			love.graphics.draw(images.merchant,u.x,u.y,u.angle,1,1,16,16)
			love.graphics.setColor(unpack(colors[u.team]))
			love.graphics.draw(coloring.merchant,u.x,u.y,u.angle,1,1,16,16)
		end
		love.graphics.setColor(255,255,0)
		if u.gold > 0 then
			love.graphics.circle('fill',u.x,u.y,u.gold/5)
		end
	end
end
