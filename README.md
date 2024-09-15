a wrapper for the library moonchart  
for easier conversion between charts

based off of https://github.com/nebulazorua/sm-to-fnf  
and mainly because i needed to convert vslice charts to stepmania lmfao

in order to compile you need  
[mcli](https://lib.haxe.org/p/mcli/)  
[moonchart](https://github.com/MaybeMaru/moonchart) (git)  
[hxcpp](https://lib.haxe.org/p/hxcpp/)  
haxe 4.3 at the least  

how to use:  
```batch
[exeName] [chartFile] [fromFormat] [toFormat] [difficulty]
```

if there's a metadata to parse too   
you can just add a , to `[chartFile]` and then write the metadata path

```batch
[exeName] [chartFile,metadataFile] [fromFormat] [toFormat] [difficulty]
```