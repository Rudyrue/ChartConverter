a wrapper for the library moonchart  
for easier conversion between charts

based off of https://github.com/nebulazorua/sm-to-fnf  
and mainly because i needed to convert vslice charts to stepmania lmfao

in order to compile you need  
[mcli](https://lib.haxe.org/p/mcli/)  
[moonchart](https://github.com/MaybeMaru/moonchart) (git)  
[hxcpp](https://lib.haxe.org/p/hxcpp/)  
haxe 4.3 at the least  

formats to use:  
[FNF_CODENAME, FNF_KADE, FNF_LEGACY, FNF_LEGACY_FPS_PLUS, FNF_LEGACY_PSYCH, FNF_LUDUM_DARE, FNF_MARU,FNF_VSLICE, GUITAR_HERO, OSU_MANIA, QUAVER, STEPMANIA, STEPMANIA_SHARK]

how to use:  
```batch
[exeName] [chartFile] [fromFormat] [toFormat] [difficulty]
```

if there's a metadata to parse too   
you can just add a , to `[chartFile]` and then write the metadata path

```batch
[exeName] [chartFile,metadataFile] [fromFormat] [toFormat] [difficulty]
```

example:  
```batch
ChartConverter blammed-chart-pico.json,blammed-metadata-pico.json FNF_VSLICE STEPMANIA Hard
ChartConverter its-a-me-hard.json FNF_LEGACY STEPMANIA hard
```
