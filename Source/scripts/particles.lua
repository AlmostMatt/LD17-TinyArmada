--ripples and particles
function updateripples(dt)
	for i=#ripples,1,-1 do
		local r = ripples[i]
		r.t = r.t - 1
		if r.t == 0 then table.remove(ripples,i) end
	end
end

function drawripples()
	love.graphics.setLineWidth(2)
	for i,r in ipairs(ripples) do
		local n = r.t/r.ti
		n=n^2
		love.graphics.setColor(0,0,0,80*n)
		love.graphics.circle('line',r.x,r.y,r.s*(1-n),16)
		--love.graphics.setColor(0,0,0,64*n)
		--love.graphics.circle('fill',r.x,r.y,100*(1-n),16)
	end
end

firecolors = {
	[0.0]	= {255,255,255,200},--white
	[0.01]	={255,255,0,190},--yellow
	[0.2]	= {255,0,0,140},--red
	[0.3]	= {0,0,0,64},--black
	[1.0]	= {0,0,0,0},
}

function burn(x,y,size)
	local angle = math.random()*6.3-- -0.5+0.3/(0.5+math.random()*0.5)
	local speed = 10+math.random(10,40)*size/20
	table.insert(particles,{x=x,y=y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,t=100,ti=100,s=size})
end

function updateparticles(dt)
	for i = #particles,1,-1 do
		local p = particles[i]
		p.t = p.t-1
		p.x=p.x+p.vx*dt
		p.y=p.y+p.vy*dt
		
		local windx,windy = 100,-10
		p.vx = p.vx*0.98+windx*dt
		p.vy = p.vy*0.98+windy*dt
		
		if p.t == 0 then table.remove(particles,i) end
	end
end

function drawparticles()
	for i,p in ipairs(particles) do
		local n = 1-p.t/p.ti
		
		local s = p.s*(0.4+n*0.6)--^2 + 2*math.max(0,p.s*(n-0.3))
		
		local r,g,b,a = 255,255,255,200
		if n>0.25 then r=math.max(0,255*(0.3-n)/0.05) end
		if n>0.15 then g=math.max(0,255*(0.25-n)/0.1) end
		if n>0.0 then b=math.max(0,255*(0.15-n)/0.15) end
		if n>0.3 then a=math.max(0,200* ((1-n)/0.7)^2 ) end
		love.graphics.setColor(r,g,b,a)
		love.graphics.circle('fill',p.x,p.y,s)
	end
end