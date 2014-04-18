--AI


--goals:
--3 traders, 1 galley, 5 traders, 3 galleys, 8 traders, oo galleys
count = 0

function updateAI(dt)
	count = count+dt
	
	if count > 1 then
		count = 0
		for AI = 2,numplayers do
			if not player[AI].defeated then
				local galleys = {}
				local merchants = {}
				local colonies = {}
				local notgalleys = {}
				for i,u in ipairs(units) do
					if u.team==AI then
						if u.t == GALLEY then table.insert(galleys,u)
						elseif u.t == MERCHANT then table.insert(merchants,u)
						else table.insert(colonies,u)
						end
						if u.t ~= GALLEY then table.insert(notgalleys,u) end
					end
				end
				--building units
				if #merchants<2 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys<1 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				elseif #merchants<3 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys<2 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				elseif #merchants<5 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys<3 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				elseif #merchants<8 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys<6 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				elseif #merchants<12 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys < 10 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				elseif #merchants<20 then
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],MERCHANT)
				elseif #galleys < 20 then --don't want to lag that much so upper limit
					build(player[AI].capitals[math.random(1,#player[AI].capitals)],GALLEY)
				end
				--merchants
				for i,u in ipairs(merchants) do
					--nonredundant harvesting
					if not u.tradewith then
						--
						local closest = nil
						local dist = math.huge 
						for i2,u2 in ipairs(units) do
							if u2.t == COLONY then
								local taken = false
								for i3,u3 in ipairs(merchants) do
									if u3.tradewith == u2 then
										taken = true
									end
								end
								if not taken then
									local d = distance(u.x,u.y,u2.x,u2.y)
									if d < dist then
										dist = d
										closest = u2
									end
								end
							end
						end
						if closest then
							u.tradewith = closest
							u.loading = true
							u.path = findpath(u.x,u.y,closest.dock.x,closest.dock.y)
						end
					end
				end			
				--galleys/colony protecting
				for i2,c in ipairs(notgalleys) do
					--defend
					--go to enemy unit that is closest to a friendly unit
					--or go to colony that is most likely to be attacked
					local cu = nil
					local cud = math.huge
					for i3,u2 in ipairs(galleys) do
						if not u2.busy then
							local d = distance(u2.x,u2.y,c.x,c.y)
							if d < cud then
								cud = d
								cu = u2
							end
						end
					end
					local ce = nil
					local ced = math.huge
					for i3,e in ipairs(units) do
						if e.team ~= AI and e.t == GALLEY then
							local d = distance(e.x,e.y,c.x,c.y)
							if d < ced then
								ced = d
								ce = e
							end
						end
					end
					if ce and cu and ced-100 < cud then
						--in danger!
						cu.busy = true
						cu.path = findpath(cu.x,cu.y,ce.x,ce.y)
					end
				end
				if #merchants > 0 then
					for i2,u2 in ipairs(galleys) do
						if not u2.path then
							u2.busy = nil
							local dest = merchants[math.random(1,#merchants)].tradewith
							if dest then
								u2.path = findpath(u2.x,u2.y,dest.dock.x,dest.dock.y)
							end
						end
					end
				end
					--attack
					--if have more galleys than an opponent, or if an opponent has an unguarded traderoute, attack it.
					--flee
					--if outnumbered, run away to own base or to other galleys
				--[[local mindd = math.huge
				local minp = nil
				for i,p in ipairs(player) do
					if not (p.defeated) and not i == AI then
						for i,c in ipairs(p.capitals) do
							local dd = distance(c.x,c.y,player[AI].x,player[AI].y)
							if dd < mindd then
								mindd = dd
								minp = p
							end
						end
					end
				end
				if minp then
					--if #galleys > #closestenemygalleys+1 then
					--	for i,u in ipairs(galleys) do
					--		attack closestcapital
					--	end
					--end
				end
				--]]
			end
		end
	
	end
	
end
