# Pokemon Yellow Sound Visualizer
This is a little side project of mine because I was interested in the gameboy color registers FF76 and FF77 as those are not officially used anywhere, so I wrote up this sound test that at the same time displays the contents of those registers on screen, see this video I've made for it in action:  
https://www.youtube.com/watch?v=GRSHwWeeRaM  
You can grab the current version from the "release" tab on top of the page, it comes in form of ready-to-use .sav files as well as installers that are a set of inputs you can run in the emulator BizHawk2 or GameBoy Interface to install it onto a real cartridge as I have done in that video, to see how to install it on a real cartridge see the README.md details of my other repository:  
https://github.com/FIX94/gameboy-audio-dumper  
I did test it on various devices and it works perfect on a gameboy color, a gameboy advance sp and a gameboy player.  
The only device it did not work on was the original gameboy which makes sense as those registers are in the gameboy color range of extra registers, however the sound test aspect still works great on it, there are just no visual updates, the volume bars are always full on it.  
Also I dont know how many emulators actually support those unofficial registers, it is supported at least in my own emulator:  
https://github.com/FIX94/fixGB  
To learn how to compile this project you can just read the technical details on my audio dumper repository I linked before, it is based on the sender of that project.  
