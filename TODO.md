## mechanics later on
- unlock area conditions:
    - by resources (money, when paid, set player state), 
    - by task (when done set player state), 
    - by level (the foundation already there, not yet utilized),
    - by rebirths (maybe similar like levels)
    - by rarity/tier (have at least this and that to enter)
    - by variation (have a diamond variation blabla)
    - by item rate (have item rate of 2.00 B)

- unlock npcs?

- wager or "trials" like in Inscryption:
    - 👉 "Trials" = conditional gambles where you contest your deck’s composition for a prize.

- npcs responds differently to different game states

- I already have setup models for npcs (but have not yet try to implement tho): 
    - wandering trader: random and exclusive items
    - potion shop: buy permanent buffs
    - junk shop: can sell

- rebirth system

- buff system

- Items Config refactor (add tiers and variations): 
```lua
ItemsConfig = {
    ItemId: string,
    DisplayName: string,
    Rate: string,
    Tier: {"common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"},
    Variations: {"none" | "Copper" | "Silver" | "Gold" | "Diamond" }
}
```

- global/universal events using MemoryStore:
    - player sends griefs onto all server
    - other players have ways to protect themselves