--interface

function drawinterface()
	love.graphics.setLineWidth(2)
	love.graphics.setColor(0,0,0,64)
	love.graphics.rectangle('fill',0,0,100,20)
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle('line',0,0,100,20)
	love.graphics.print('Gold: '..player[1].gold,10,15)
	
	local ok = false
	for i,c in ipairs(player[1].capitals) do
		if c.selected then
			ok = true
		end
	end
	if ok then
		love.graphics.setLineWidth(2)
		love.graphics.setColor(0,0,0,64)
		love.graphics.rectangle('fill',width,height,-175,-80)
		love.graphics.setColor(0,0,0,255)
		love.graphics.rectangle('line',width,height,-175,-80)
		love.graphics.setLineWidth(1)
		
		love.graphics.setColor(255,255,255,64)
		if my > height - 70 and my < height - 20 then
			if mx > width-75 and mx < width - 25 then
				love.graphics.rectangle('fill',width-75,height-70,50,50)
			elseif mx > width - 150 and mx < width - 100 then
				love.graphics.rectangle('fill',width-150,height-70,50,50)
			end
		end
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle('line',width-75,height-70,50,50)
		love.graphics.setColor(255,255,255)
		love.graphics.draw(images.merchant,width-125-16,height-45-16)
		love.graphics.setColor(0,0,0)
		love.graphics.printf(cost[MERCHANT],width-150,height-5,50,'center')
		love.graphics.rectangle('line',width-150,height-70,50,50)
		love.graphics.setColor(255,255,255)
		love.graphics.draw(images.galley,width-50-16,height-45-16)
		love.graphics.setColor(0,0,0)
		love.graphics.printf(cost[GALLEY],width-75,height-5,50,'center')
	end
		
end