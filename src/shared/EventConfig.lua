-- src/shared/EventConfig.lua  | rotating live events; one is active per week, forever
local EventConfig = {}

-- droppingsMult stacks with your other multipliers; luckMult biases dispenser rolls higher
EventConfig.Events = {
	{ id = "quackfest",  name = "🎉 Quackfest",       blurb = "Double Duck Droppings all week!", droppingsMult = 2.0, luckMult = 1.0 },
	{ id = "luckytide",  name = "🍀 Lucky Tide",      blurb = "x2 luck on every pull!",          droppingsMult = 1.0, luckMult = 2.0 },
	{ id = "goldrush",   name = "💰 Gold Rush",       blurb = "+50% Droppings & +50% luck!",     droppingsMult = 1.5, luckMult = 1.5 },
	{ id = "shimmerstorm",name= "✨ Shimmer Storm",    blurb = "Triple shiny chance & x1.5 earn!",droppingsMult = 1.5, luckMult = 1.2 },
	{ id = "duckmoon",   name = "🌙 Duck Moon",       blurb = "Night Trail vibes — x2.5 luck!",  droppingsMult = 1.0, luckMult = 2.5 },
	{ id = "jeepjam",    name = "🚙 Jeep Jam",        blurb = "x3 Droppings — the big one!",      droppingsMult = 3.0, luckMult = 1.0 },
	{ id = "festival",   name = "🎪 Duck Festival",   blurb = "x2 earn AND x2 luck!",            droppingsMult = 2.0, luckMult = 2.0 },
}

function EventConfig.activeIndex()
	local week = math.floor(os.time() / (7 * 86400))
	return (week % #EventConfig.Events) + 1
end

function EventConfig.active()
	return EventConfig.Events[EventConfig.activeIndex()]
end

function EventConfig.endsAt()
	local week = math.floor(os.time() / (7 * 86400))
	return (week + 1) * (7 * 86400)
end

return EventConfig
