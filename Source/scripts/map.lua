--map stuff

--restart mapmaking if
--two players are too close to each other
--unable to create land (island stuck between two other islands)
--create a capital too close to edge of world and therefore create land touching the edge of the world

function makeground(x,y)
	if x == 1 or y == 1 or x == mw or y == mh then
		print("Capital close to shore")
		return nil
	end
	
	dockable[x][y] = false
	map[x][y] = true
	for t = 1,5 do
		local x,y = gu*(x-1)+math.random(1,gu-1),gu*(y-1)+math.random(1,gu-1)
		local s = math.random(3,7)
		table.insert(trees,{x=x,y=y,s=s})
	end
	return true
end

function makemap()
	trees={}
	groundblobs={}
	
	local numislands = 20
	local numland = 12
	local numdocks = 1
	--make islands!
	math.randomseed(os.time()+math.random(100))
	math.random()
	mw,mh = width/gu,height/gu--map width and height (in tiles)
	map = {}
	local buildings = {}
	dockable = {}
	
	for x = 1,mw do map[x]={} buildings[x]={} end
	for x = 1,mw do dockable[x]={} for y=1,mh do dockable[x][y] = true end end
	--make islands!
	local i = 0
	while i < numislands do --number of islands
		local x = math.random(2,mw-1)
		local y = math.random(2,mh-1)
		if not map[x][y] then
			--print("Island at "..x..','..y)
			map[x][y] = true
			local bits = {{x,y}}
			local n = 1
			local tries = 0
			while n < numdocks+numland do --number of land tiles + number of docks to make up an island
				local index = math.random(1,#bits)
				local x,y = unpack(bits[index])
				local ox = math.random(-1,1)
				local oy = math.random(-1,1)
				tries = tries + 1
				if tries > 100 then print("Too many tries") return nil end
				if (ox==0 or oy==0) and x+ox>1 and x+ox<mw and y+oy>1 and y+oy< mh and not map[x+ox][y+oy] and (n<numland or dockable[x+ox][y+oy]) then
					tries = 0
					if n < numland then --number of land tiles
						makeground(x+ox,y+oy)
						table.insert(bits,{x+ox,y+oy})
					else
						local team = 0
						if i >= numislands-numplayers then
							team = 1+i%numplayers
							spawn(gu*(x-0.5-0.5*(ox+oy)),gu*(y-0.5-0.5*(oy+ox)),CAPITAL,0,team)
							player[team].capitals = {units[#units]}
							for cx = x-0.5-0.5*(ox+oy),x+0.5-0.5*(ox+oy) do
							for cy = y-0.5-0.5*(ox+oy),y+0.5-0.5*(ox+oy) do
								if buildings[cx][cy] then
									--there is already a building here: find it and move it
									print("Ooops!")
								end
								buildings[cx][cy] = true
								if not map[cx][cy] then
									local ok = makeground(cx,cy)
									if not ok then return nil end
								end
								--and ideally remove this tile from "bits" as well in order to not tree it
							end
							end
						else
							spawn(gu*(x-0.5),gu*(y-0.5),COLONY,0,team)
							buildings[x][y] = true
						end
						units[#units].dock = {x=gu*(x+ox-0.5),y=gu*(y+oy-0.5),angle=math.atan2(oy,ox)}
						table.remove(bits,index)
					end
					--plus one to land count
					n = n+1 
				end
			end
			--plus one to island count
			i = i+1
		end
	end
	
	--fix colonies/docks whatever
	--print("Potentially moving buildings")
	bits={}
	for x = 2,mw-1 do
		for y,v in pairs(map[x]) do
			if not buildings[x][y] then
				table.insert(bits,{x,y})
			end
		end
	end
	for i,u in ipairs(units) do
		--note, this will mess up with capitals because of their funny position size thing
		local needmove = true
		while map[math.ceil(u.dock.x/gu)][math.ceil(u.dock.y/gu)] or not findpath(u.dock.x,u.dock.y,gu/2,gu/2) do
			if needmove then
				needmove = false
				--print('need to move!')
			end
			local moved = false
			while not moved do
				local i = math.random(1,#bits)
				local x,y = unpack(bits[i])
				local ox = math.random(-1,1)
				local oy = math.random(-1,1)
				if (ox==0 or oy==0) and x+ox>1 and x+ox<=mw-1 and y+oy>1 and y+oy<= mh-1 and dockable[x+ox][y+oy] then
					u.x,u.y = gu*(x-0.5),gu*(y-0.5)
					u.dock = {x=gu*(x+ox-0.5),y=gu*(y+oy-0.5),angle=math.atan2(oy,ox)}
					moved = true
					buildings[x][y] = true
					for ox2=-1,1 do for oy2 = -1,1 do
						dockable[minmax(x+ox+ox2,1,mw)][minmax(y+oy+oy2,1,mh)] = false
					end end
				end
			end
		end
	end
	
	local mind = math.huge
	for i1,p1 in ipairs(player) do
		for i2,p2 in ipairs(player) do
			if i1 ~= i2 then
				local d = distance(p1.capitals[1].x,p1.capitals[1].y,p2.capitals[1].x,p2.capitals[1].y)
				if d < mind then mind=d end
			end
		end
	end
	if mind < 160^2 then
		print("Players too close")
		return nil
	end
	
	return true
end

function drawgrid()
	love.graphics.setLineWidth(1)
	love.graphics.setColor(150,180,175)
	for x = gu,width,gu do
		love.graphics.line(x,0,x,height)
	end
	for y = gu,height,gu do
		love.graphics.line(0,y,width,y)
	end
end

function drawmap()
	
	love.graphics.setLineWidth(1)
	for i,u in ipairs(units) do
		if u.team ~= 0 and healradius[u.t] then
			local r,g,b = unpack(colors[u.team])
			local a1,a2 = 32,128
			if u.team == 3 then a1,a2 = 64,190 end
			love.graphics.setColor(r,g,b,a1)
			love.graphics.circle('fill',u.x,u.y,healradius[u.t],32)
			love.graphics.setColor(r,g,b,a2)
			love.graphics.circle('line',u.x,u.y,healradius[u.t],32)
		end
	end
	
	fillmap()
	--[[
	--draw ground blobs
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0,100,30)
	for i,g in ipairs(groundblobs) do
		love.graphics.circle('fill',g.x,g.y,g.s+4)
	end
	love.graphics.setColor(0,120,40)
	for i,g in ipairs(groundblobs) do
		love.graphics.circle('fill',g.x,g.y,g.s+2)
	end
	love.graphics.setColor(0,150,50)
	for i,g in ipairs(groundblobs) do
		love.graphics.circle('fill',g.x,g.y,g.s-1)
	end]]
	outlinemap()
	
	drawtrees()
	
	
end


function drawtrees()
	love.graphics.setColor(0,50,16)
	for i,t in ipairs(trees) do
		love.graphics.circle('fill',t.x,t.y,t.s+2)
	end
	love.graphics.setColor(0,100,30,200)
	for i,t in ipairs(trees) do
		love.graphics.circle('fill',t.x+1,t.y-1,t.s)
	end
	love.graphics.setColor(0,255,50,64)
	for i,t in ipairs(trees) do
		love.graphics.circle('fill',t.x+1,t.y-1,t.s*0.7)
	end
	love.graphics.setColor(0,255,50,48)
	for i,t in ipairs(trees) do
		love.graphics.circle('fill',t.x+1,t.y-1,t.s*0.5)
	end
end

function fillmap()
	--[[love.graphics.setColor(185,225,155)
	for x = 1,mw do
		for y,t in pairs(map[x]) do
			love.graphics.rectangle('fill',x*gu+10,y*gu+10,-gu-20,-gu-20)
		end
	end
	love.graphics.setColor(100,176,26)
	for x = 1,mw do
		for y,t in pairs(map[x]) do
			love.graphics.rectangle('fill',x*gu+5,y*gu+5,-gu-10,-gu-10)
		end
	end
	love.graphics.setColor(50,125,26)
	for x = 1,mw do
		for y,t in pairs(map[x]) do
			love.graphics.rectangle('fill',x*gu+2,y*gu+3,-gu-4,-gu-4)
		end
	end]]
	love.graphics.setColor(0,76,26)
	for x = 1,mw do
		for y,t in pairs(map[x]) do
			love.graphics.rectangle('fill',x*gu,y*gu,-gu,-gu)
		end
	end
end
function outlinemap()
	love.graphics.setColor(255,255,255)
	for x = 1,mw do
		for y,t in pairs(map[x]) do
			for ox = -1,1 do
				for oy=-1,1 do
					if not map[x+ox][y+oy] and (ox==0 or oy == 0 or (not map[x+ox][y] and not map[x][y+oy]))then
						love.graphics.draw(images.shore,(x-0.5)*gu,(y-0.5)*gu,math.atan2(oy,ox),1,1,16,16)
					end
				end
			end
		end
	end	
end