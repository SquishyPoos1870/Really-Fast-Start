local robot_item = table.deepcopy(data.raw.item["construction-robot"])
local robot_entity = table.deepcopy(data.raw["construction-robot"]["construction-robot"])

robot_item.name = "fast-start-construction-robot"
robot_item.localised_name = {"item-name.fast-start-construction-robot"}
robot_item.localised_description = {"item-description.fast-start-construction-robot"}
robot_item.place_result = "fast-start-construction-robot"
robot_item.order = (robot_item.order or "") .. "-fast-start"

robot_entity.name = "fast-start-construction-robot"
robot_entity.localised_name = {"entity-name.fast-start-construction-robot"}
robot_entity.localised_description = {"entity-description.fast-start-construction-robot"}

if robot_entity.minable then
  robot_entity.minable.result = "fast-start-construction-robot"
end

-- Only this custom starter robot is faster. Vanilla construction/logistic robots stay untouched.
local multiplier = 3
if robot_entity.speed then
  robot_entity.speed = robot_entity.speed * multiplier
end
if robot_entity.max_speed then
  robot_entity.max_speed = robot_entity.max_speed * multiplier
end
if robot_entity.speed_multiplier_when_out_of_energy then
  robot_entity.speed_multiplier_when_out_of_energy = math.min(robot_entity.speed_multiplier_when_out_of_energy * 1.5, 1)
end

-- Keep it obtainable only from this mod's starting kit/command.
robot_item.flags = robot_item.flags or {}
robot_item.hidden = false
robot_item.hidden_in_factoriopedia = false
robot_item.auto_recycle = false

-- Do not add a recipe or technology; this is a dedicated starter bot.
data:extend({ robot_item, robot_entity })
