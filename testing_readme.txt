Step by step testing for intertwine:

1. Enable Console in conf.lua
2. Enable cheatcodes Boolean on line 2 of main.lua

next:

1. Run love . on the main file and check for errors on boot
2. Check for game loading success
   - Does The UI, Sprites, and Music show up on boot

3. Check Level change
   - Does finishing level move you to next level and correctly show win overlay
4. Check controls
   - Can you move character
   - does target (green) character move inversely to blue
5. Check entity events
   - Does landing on lava tile reset level
        - Does the level reset include collected items?
	- Do unique death sounds play for each entity?
   - Does collecting items remove them from draw and add to item count?
   - Does winning level work correctly
   - Collision sounds?
6. Visual Checks
   - Are sprites drawn blurry?
   - Clipping? Blinking?

What this testing method cannot account for:
Bugs specific to hardware, or operating system
Minor visual or audio bugs
Long term memory leaks - love gives no warnings as long as code runs
Incompatibility with assistive technology
