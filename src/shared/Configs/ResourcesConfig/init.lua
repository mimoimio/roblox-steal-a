local ResourcesConfig = {}

for i, m: ModuleScript in script:GetChildren() do
	ResourcesConfig[m.Name] = require(m)
end
warn("RESOURCES CONFIG", ResourcesConfig)
return ResourcesConfig
