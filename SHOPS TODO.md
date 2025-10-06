
# Shops implemention

## Normal Shop
There's normal shop, you visit it every time, cus it's part of the loop. You spend money to get better stuffs,
> sells common and uncommon stuffs:
- box, stick, rock
- crystal, mimoimior, radiooze
- rare, epic, legendary, mythic items comes once in a while
- variations are all the same. This gives ways for shops to give variations
- making ItemSpawnService's spawn rate rewarding but has to make it very rare
> UX:
- different shops content for different players? -> can do refreshes as they like
- if not, it will be public
> UI:
- ScreenGuis only? 
    - currently only texts containing
        - Name
        - Variation & Tier (coloreds)
        - Rate
    - later needs to use image, if small could use small images, dont need to use viewportframes, good for memory
- Models?
    - needs to think about the structure, it needs to be wide, or if not, resize/scale down to suitable sizes. Seems good
    - server (most likely) or client?
---
## Wandering Trader
There's wandering trader, Guaranteed one or two exclusive items at a price.
- Spawns once in a while, needs to do server life based spawn with spawn rng
- One thing is always there, a RARE tier and SILVER variation or both is the minimum appearance on trader spawn
- maybe sells a rare potion
> UX:
- is public. First come first serve
- notification on spawn? maybe not. currently only do notifications on Strange spawn
>UI
- ScreenGuis only? 
    - currently only texts containing
        - Name
        - Variation & Tier (coloreds)
        - Rate
    - later needs to use image, if small could use small images, dont need to use viewportframes, good for memory
- Models?
    - needs to think about the structure, it needs to be wide, or if not, resize/scale down to suitable sizes. Seems good
    - server (most likely) or client?

---
## Normal Potion Seller
Sells common to uncommon with unlikely occurrence of rare and epic tier
- is like normal shop, you go here everyday
- potions have main effects, and side effects
- 

---
# Here's a guideline. Make the player think about choices. Decision making. More pivotal choices. Sinks and Taps