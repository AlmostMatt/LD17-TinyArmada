function love.load()
	INIT = 0
	LOADING = 1
	MAKINGMAP = 2
	PLAYING = 3
	state = INIT
	width,height = love.graphics.getWidth(),love.graphics.getHeight()
	flarge = love.graphics.newFont(64)
end

function load()
	--generic stuff
	love.graphics.setBackgroundColor(170,200,255)
	if not title then title = love.graphics.getCaption() end
	gu = 20 --gridunit
	--require scripts
	require('scripts/units.lua')
	require('scripts/shots.lua')
	require('scripts/particles.lua')
	require('scripts/map.lua')
	require('scripts/interface.lua')
	require('scripts/pathfind.lua')
	require('scripts/AI.lua')
	--love.graphics.setLineStyle('smooth')
	images={}
	images.colony = love.graphics.newImage('art/colony.png')
	images.capital = love.graphics.newImage('art/capital.png')
	images.merchant = love.graphics.newImage('art/merchant.png')
	images.galley = love.graphics.newImage('art/galley.png')
	images.dock = love.graphics.newImage('art/dock.png')
	images.shore = love.graphics.newImage('art/shore1.png')
	coloring={}
	coloring.colony = love.graphics.newImage('art/colony2.png')
	coloring.capital = love.graphics.newImage('art/capital2.png')
	coloring.merchant = love.graphics.newImage('art/merchant2.png')
	coloring.galley = love.graphics.newImage('art/galley2.png')
	--game stuff
	player={}
	camx = 0
	camy = 0
	camscale = 1
	T = 0.01
	overtime = 0
	frame = 0
	frame2=0
	fsmall = love.graphics.newFont(12)
	fmedium = love.graphics.newFont(20)
	lastclick = os.time()
end

function setup()
	for i = 1,numplayers do
		player[i]={gold=200}
	end
	ripples = {}
	particles = {}
	shots = {}
	local ok
	while not ok do
		units = {}
		ok = makemap()
	end
	hover={}	
	selection = player[1].capitals
	player[1].capitals[1].selected = true
	PAUSED = true
end

function love.update(dt)
	mx,my = love.mouse.getPosition()
	if state == LOADING then
		load()
		state = MAKINGMAP
	elseif state == MAKINGMAP then
		setup()
		love.graphics.setFont(fsmall)
		state = PLAYING
	elseif state == PLAYING then
		--selection box
		hover = {}
		local x1,y1 = mx,my
		local x2,y2 = mx,my
		if clickedat then x2,y2 = unpack(clickedat) end
		for i,u in ipairs(units) do
			if u.x+size[u.t]>math.min(x1,x2) and u.x-size[u.t]<math.max(x1,x2) and
			u.y+size[u.t]>math.min(y1,y2) and u.y-size[u.t]<math.max(y1,y2) then
				table.insert(hover,u)
			end
		end
		--
		if not PAUSED then
			if dt > 0.1 then dt = 0.1 end
			love.graphics.setCaption(title..' [FPS: '..love.timer.getFPS()..']')
			
			overtime = overtime + dt
			while overtime > T do
				overtime = overtime - T
				fixedupdate(T)
			end
		end
		lastx,lasty = mx,my
	end
end

function fixedupdate(dt)
	updateripples(dt)
	updateparticles(dt)
	
	--[[if frame >= 150 then
		frame = 0
		for x = 1,mw do
			for y,v in pairs(map[x]) do
				table.insert(ripples,{x=(x-0.5)*gu,y=(y-0.5)*gu,t=500})
			end
		end
	end]]
	updateAI(dt)
	
	
	unitstuff(dt)
	
	moveshots(dt)
	--
end

function build(u,t)
	if player[u.team].gold >= cost[t] then
		player[u.team].gold=player[u.team].gold-cost[t]
		spawn(u.dock.x,u.dock.y,t,u.dock.angle,u.team)
		units[#units].path={{u.dock.x+gu*0.8*math.cos(u.dock.angle),u.dock.y+gu*0.8*math.sin(u.dock.angle)}}
	end
end

function select(u)
	lastselected = u
	if not u.selected then table.insert(selection,u) u.selected = true end
end

function love.keypressed(key)
	if state ~= PLAYING then return nil end
	for i,selected in ipairs(selection) do
		if selected.t==CAPITAL then
			if key == '1' or key == '2' then
				if PAUSED then
					PAUSED = false
				end
			end
			if key == '1' then
				build(selected,MERCHANT)
			elseif key == '2' then
				build(selected,GALLEY)
			end
		end
	end
	
	if key == 'r' then
		print 'Restarting'
		state=MAKINGMAP
	elseif key == 'escape' then
		love.event.push('q')
	end
end

function love.mousepressed(x,y,button)
	if state ~= PLAYING then return nil end
	if button == 'l' then
		click = os.time()
		local ok = false
		for i,c in ipairs(player[1].capitals) do
			if c.selected == true and x > width-175 and y>height-80 then
				ok = true--whether or not a capital is selected and tryign to build a unit
				if y > height-70 and y<height-20 then
					if x > width - 150 and x < width - 100 then
						love.keypressed('1')
					elseif x > width - 75 and x < width - 25 then
						love.keypressed('2')
					end
				end
			end
		end
		if not ok then
			if not love.keyboard.isDown('lshift') then
				for i,u in ipairs(selection) do u.selected = nil end
				selection = {}
			end
			if click-lastclick < 0.075 and #hover > 0 then --double click!
				if hover[1].team == 1 and hover[1] == lastselected then
					for i,u in ipairs(units) do
						if u.team == 1 and u.t == hover[1].t then
							select(u)
						end
					end
				end
			else
				clickedat={x,y} --normal click stuff
			end
		end
		lastclick = click
	elseif button == 'r' then
		for i,u in ipairs(selection) do
			if isboat(u.t) then
				u.path=findpath(u.x,u.y,x+math.random(-5,5),y+math.random(-5,5))
				if u.t == MERCHANT then
					u.tradewith = nil
					u.loading = false
					u.dropoff = false
					for i,u2 in ipairs(hover) do
						if u2.t == COLONY then u.loading = true u.dropoff = false u.tradewith = u2 u.path = findpath(u.x,u.y,u2.dock.x,u2.dock.y) end
						if u2.t == CAPITAL and u2.team == u.team then u.dropoff = true u.loading = false u.path = findpath(u.x,u.y,u2.dock.x,u2.dock.y) end
					end
				end
			end
		end
	end
end
function love.mousereleased(x,y,button)
	if state ~= PLAYING then return nil end
	if button == 'l' and clickedat then
	if (x-clickedat[1])^2+(y-clickedat[2])^2 < 16 and #hover>0 then
		if hover[1].team == 1 then
			select(hover[1])
		end
	else
		for i,u in ipairs(hover) do
			if u.team == 1 then
				select(u)
			end
		end
	end
	clickedat=nil
	end
	
	--[[if path then
		table.insert(path,{x,y})
		selected.path = path
		path = nil
		selected = nil
	end]]
	
end

function love.draw()
	if state == INIT then
		love.graphics.setColor(0,0,0)
		love.graphics.setFont(flarge)
		love.graphics.printf("Loading...",0,height/2+16,width,'center')
		state = LOADING
	elseif state == MAKINGMAP then
		love.graphics.printf("Generating a map...",0,height/2+16,width,'center')
	elseif state == PLAYING then
		--drawgrid()
		drawripples()
		drawmap()
		love.graphics.setLineWidth(2)
		showselected()
		--
		love.graphics.setLineWidth(1)
		if clickedat then
		local x1,y1 = mx,my
		local x2,y2 = unpack(clickedat)
		love.graphics.setColor(255,255,255,32)
		love.graphics.rectangle('fill',x1,y1,x2-x1,y2-y1)
		love.graphics.setColor(255,255,255,128)
		love.graphics.rectangle('line',x1,y1,x2-x1,y2-y1)
		end
		--
		drawpaths()
		drawunits()
		drawshots()
		drawparticles()
		drawinterface()
		--[[if PAUSED then
			love.graphics.setLineWidth(2)
			love.graphics.setColor(255,255,255,150)
			love.graphics.rectangle('fill',width/2-100,height/2-10,200,20)
			love.graphics.setColor(0,0,0)
			love.graphics.rectangle('line',width/2-100,height/2-10,200,20)
			love.graphics.printf("Press anything to begin.",0,height/2+4,width,'center')
		end]]
		if #player[1].capitals == #player then
			--WIN
			love.graphics.setColor(255,255,255,64)
			love.graphics.rectangle('fill',0,0,width,height)
			love.graphics.setColor(0,0,0)
			love.graphics.setFont(flarge)
			love.graphics.printf("VICTORY!",0,height/2+16,width,'center')
			love.graphics.setFont(fmedium)
			love.graphics.printf("Press R to generate a new map",0,height/2+36,width,'center')
			love.graphics.setFont(fsmall)
		elseif #player[1].capitals == 0 then
			--defeat
			love.graphics.setColor(255,255,255,64)
			love.graphics.rectangle('fill',0,0,width,height)
			love.graphics.setColor(0,0,0)
			love.graphics.setFont(flarge)
			love.graphics.printf("DEFEAT!",0,height/2+16,width,'center')
			love.graphics.setFont(fmedium)
			love.graphics.printf("Press R to generate a new map",0,height/2+36,width,'center')
			love.graphics.setFont(fsmall)
		end
	end
end