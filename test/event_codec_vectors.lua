-- shared by core and rs_integration codec tests; values computed independently of the lua codec
return {
	hashes = {
		{ name = "", hex = "cbf29ce484222325" },
		{ name = "a", hex = "af63dc4c8601ec8c" },
		{ name = "src.pvs.debug.sectors", hex = "d26f1a966803c500" },
		{ name = "src.world.deleteBlock", hex = "23812f5a43f24f0d" },
	},
	encodings = {
		{ name = "no arguments", hex = "535243410100000000", args = {}, n = 0 },
		{
			name = "every tag",
			hex = "53524341010000000700010203fffffffffffffffe04400400000000000005000000026869060000000300ff10",
			n = 7,
			args = function(codec)
				return { nil, false, true, -2, 2.5, "hi", codec.blob("\0\255\16") }
			end,
		},
	},
}
