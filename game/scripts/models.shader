biomass 
{
	deformVertexes wave 1 sin 0 4 1 0.5
	{
		map models/biomass
		rgbGen lightingDiffuse
	}
}

dotpart
{
	{
		map particles/dot
		rgbGen vertex
		alphaGen vertex
		alphaFunc GE128
	}
}

tracer
{
	{
		map particles/tracer
		blendFunc blend
		rgbGen vertex
		alphaGen vertex
		alphaFunc GE128
	}
}

mf1
{
	{
		map particles/muzzleflash
		rgbGen vertex
		alphaGen vertex
		alphaFunc GE128
	}
}

mf2
{
	{
		map particles/muzzleflash2
		rgbGen vertex
		alphaGen vertex
		alphaFunc GE128
	}
}

mf3
{
	{
		map particles/muzzleflash3
		rgbGen vertex
		alphaGen vertex
		alphaFunc GE128
	}
}