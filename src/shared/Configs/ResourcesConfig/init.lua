local ResourcesConfig = {}

for i, m: ModuleScript in script:GetChildren() do
	ResourcesConfig[m.Name] = require(m)
end
warn("RESOURCES CONFIG", ResourcesConfig)
return ResourcesConfig

--[[

	What do you sink player's resources to?
		Cosmeticsw
		Upgrades
		Buffs
		Perks

	How do you orchestrate the music? 
	How do you dance? 
	How do you integrate one onto another? 
	How should you engineer it? 
	How do you place the rhythm?
	What's the rhythm?
	What's the pace of the story?

	The Micro rhythm:
		Money loop: increment every second.
		items spawn: spawn 100 randomly chosen items at once > change randomly chosen to a rhythm
		pick up items: positions area randomized too > change to a set of conditions

		rhythm: a repeating pattern
		un random
		un arbitrary
		conditional
		measured
		accent
		pulse

		leading the viewer's
		mysteries?
		leading questions

	1. Copy: 
	2. Integrate: 
	3. Replace: 
	4. Explore: 
	5. Perseverence: Debugging


	people stayed for the dance, i think
	but they dont see the layers
]]

--[[

Area unlocks: pay this to get here. have this to get here

]]
