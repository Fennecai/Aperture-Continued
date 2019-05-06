AddCSLuaFile()

if not LIB_APERTURECONTINUED then
	print("Error: Aperture lib does not exist or could not be found.")
	return
end

-- ================================ ITEM DROPPER ============================

LIB_APERTURECONTINUED.ITEM_DROPPER_ITEMS = {
	[1] = "Weighted Storage Cube",
	[2] = "Old Weighted Storage Cube",
	[3] = "Weighted Companion Cube",
	[4] = "Edgeless Safety Cube",
	[5] = "Discouragement Redirection Cube",
	[6] = "Frankenturret"
}
