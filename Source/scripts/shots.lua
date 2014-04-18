--shots

function moveshots(dt)
	for i = #shots,1,-1 do
		local s = shots[i]
		s.x = s.x+s.vx*dt
		s.y = s.y+s.vy*dt
		s.z = s.z+s.vz*dt
		s.vz=s.vz-100*dt--gravity
		for i2,u in ipairs(units) do
			if u.team~=s.shooter.team then
				local dx,dy = u.x-s.x,u.y-s.y
				local dd = dx*dx+dy*dy
				if dd < size[u.t]^2 then
					u.hp = u.hp-1
					if u.hp<=0 then
						if u.selected then
							for i3,u2 in ipairs(selection) do
								if u2.hp<=0 then table.remove(selection,i3) break end
							end
						end
						if u.t == COLONY or u.t == CAPITAL then
							u.hp = maxhp[u.t]
							if u.t == CAPITAL then
								--u.t = COLONY
								--u.x = u.dock.x-gu*math.cos(u.dock.angle)
								--u.y = u.dock.y-gu*math.sin(u.dock.angle)
								for i3,c in ipairs(player[u.team].capitals) do
									if c == u then
										table.remove(player[u.team].capitals,i3)
										break
									end
								end
								if #player[u.team].capitals == 0 then
									for i4,u3 in ipairs(units) do if i4~=i2 and u3.team==u.team then u3.team = s.shooter.team end end
									player[u.team].defeated = true
									if u.team == 1 then
										selection = {}
									end
									player[s.shooter.team].gold = player[s.shooter.team].gold+player[u.team].gold
								end
								table.insert(player[s.shooter.team].capitals,u)
							end
							u.team = s.shooter.team
						else
							table.remove(units,i2)
						end
					end
					table.remove(shots,i)
					break
				end
			end
		end
		if s.z<0 then
			table.insert(ripples,{x=s.x,y=s.y,t=60,ti=60,s=30})
			table.remove(shots,i)
		end
	end
end

function drawshots()
	love.graphics.setColor(0,0,0)
	--draw shots
	for i,s in ipairs(shots) do
		love.graphics.setLineWidth(1)
		local size = 0.05
		love.graphics.line(s.x,s.y,s.x-s.vx*size,s.y-s.vy*size)
		love.graphics.setLineWidth(2)
		size = 0.02
		love.graphics.line(s.x,s.y,s.x-s.vx*size,s.y-s.vy*size)
	end
	--
end