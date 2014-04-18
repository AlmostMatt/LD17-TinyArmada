--pathfinding



function raycast(x1,y1,x2,y2)
	local dx,dy=1,1
	if x2 < x1 then dx = -1 end
	if y2 < y1 then dy = -1 end
	for x = math.ceil(x1/gu),math.ceil(x2/gu),dx do
		local yin,yout
		if x == math.ceil(x1/gu) then
			yin = math.ceil(y1/gu)
		elseif dx==1 then
			yin = math.ceil( ((gu*(x-1)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		else
			yin = math.ceil( ((gu*(x)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		end
		if x == math.ceil(x2/gu) then
			yout = math.ceil(y2/gu)
		elseif dx==1 then
			yout = math.ceil( ((gu*(x)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		else
			yout = math.ceil( ((gu*(x-1)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		end
		for y = yin,yout,dy do
			if map[x][y] then
				return false
			end
		end
	end
	return true
end

function manhattan(x1,y1,x2,y2)
	return math.abs(x2-x1)+math.abs(y2-y1)
end

function minmax(v,minv,maxv)
	return math.max(math.min(v,maxv),minv)
end

--really quick a* pathfinding!
function findpath(sx,sy,fx,fy)
	local path = nil
	
	sx = minmax(sx,1,width)
	sy = minmax(sy,1,height)
	fx = minmax(fx,1,width)
	fy = minmax(fy,1,height)
	
	local stx,sty = math.ceil(sx/gu),math.ceil(sy/gu)
	local ftx,fty = math.ceil(fx/gu),math.ceil(fy/gu)
	open = {{stx,sty}}
	nodes = {}
	closed={}
	for x = 1,mw do closed[x]={} nodes[x]={} end
	nodes[stx][sty]={}
	nodes[stx][sty].g=0
	nodes[stx][sty].f=10*manhattan(stx,sty,ftx,fty)
	
	if map[ftx][fty] then
		--find nearest water tile
		local x,y = ftx,fty
		local done = false
		for n = 1,10 do
			for ox=-n,n do
				for oy=-n,n do
					if x+ox>0 and x+ox<=mw and y+oy>0 and y+oy<=mh then
						if not map[x+ox][y+oy] then
							ftx,fty = x+ox,y+oy
							fx,fy=(ftx-0.5)*gu,(fty-0.5)*gu
							done=true
							break
						end
					end
				end
				if done then break end
			end
			if done then break end
		end
	end
	
	while #open>0 and not path do
		local best = 1
		local x,y = unpack(open[1])
		local besth = nodes[x][y].f+nodes[x][y].g
		for i = 2,#open do
			x,y = unpack(open[i])
			local h = nodes[x][y].f+nodes[x][y].g
			if h < besth then
				best = i
				besth = h
			end
		end
		
		local x,y = unpack(open[best])
		for ox=-1,1 do
		for oy=-1,1 do
			if (oy~=0 or ox~=0) and x+ox>0 and x+ox<=mw and y+oy>0 and y+oy<=mh then
				local movecost = 10
				if ox~=0 and oy~=0 then movecost = 14 end
				if not closed[x+ox][y+oy] and not map[x+ox][y+oy] and not map[x+ox][y] and not map[x][y+oy] then
					if not nodes[x+ox][y+oy] then
						table.insert(open,{x+ox,y+oy})
						if x+ox==ftx and y+oy==fty then
							path={{ftx,fty}}
						end
						nodes[x+ox][y+oy]={}
						nodes[x+ox][y+oy].par={x,y}
						nodes[x+ox][y+oy].f=10*manhattan(x,y,ftx,fty)
						nodes[x+ox][y+oy].g=nodes[x][y].g+movecost
					elseif nodes[x+ox][y+oy].g > nodes[x][y].g+movecost then
						nodes[x+ox][y+oy].par={x,y}
						nodes[x+ox][y+oy].g=nodes[x][y].g+movecost
					end
				end
			end
		end
		end
		table.remove(open,best)
		closed[x][y]=true
	end
	
	--found a path
	if path then
		--work backwards from the end to make the path
		while true do
			local x,y = unpack(path[1])
			local p = nodes[x][y].par
			if p then table.insert(path,1,p)
			else break end
		end
		--convert back to game coordinates, not tiles
		if#path>1 then table.remove(path,1) end
		for i =1,#path-1 do
			path[i][1]=(path[i][1]-0.5)*gu
			path[i][2]=(path[i][2]-0.5)*gu
		end
		path[#path] = {fx,fy}
	
	--simplify path by taking diagonals for logn sections
		for i = 1,#path-2 do
			local lastvisible = i+1
			for i2 = i+2,#path do
				if raycast(path[i][1],path[i][2],path[i2][1],path[i2][2]) then
					lastvisible = i2
				else
					break
				end
			end
			while lastvisible > i+1 do
				table.remove(path,i+1)
				lastvisible = lastvisible-1
			end
		end
	end
	
	return path
end
