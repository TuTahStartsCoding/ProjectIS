# The Debt — Godot 4 Project

## โครงสร้างโปรเจกต์

```
the_debt/
├── project.godot              ← ไฟล์โปรเจกต์หลัก (เปิดด้วย Godot 4.3+)
│
├── scenes/
│   ├── MainMenu.tscn          ← หน้าแรก (Start / Setting / Exit)
│   ├── SettingScene.tscn      ← หน้าตั้งค่า (Sound / Music / Brightness)
│   ├── IntroScene.tscn        ← เนื้อเรื่อง + วิธีเล่น
│   ├── MainGame.tscn          ← เกมหลัก (เดิน + HUD + interact)
│   ├── DialogueUI.tscn        ← กล่องคุยกับ NPC
│   ├── JobSelectUI.tscn       ← เลือกงาน
│   ├── JobDescriptionUI.tscn  ← ผลลัพธ์หลังทำงาน + เลือก save/pay
│   ├── HotelPromptUI.tscn     ← popup ยืนยันการพัก
│   ├── SleepScene.tscn        ← สรุปวัน + ข้ามวัน
│   ├── VictoryScene.tscn      ← ชนะ
│   ├── LoseSceneTime.tscn     ← แพ้ (หมดเวลา)
│   └── LoseSceneEnergy.tscn   ← แพ้ (พลังงานหมด)
│
├── scripts/
│   ├── GameManager.gd         ← Autoload: state ทั้งหมด, job system, rest
│   ├── MainMenu.gd
│   ├── SettingScene.gd
│   ├── IntroScene.gd
│   ├── MainGame.gd            ← Controller หลัก, interaction flow
│   ├── Player.gd              ← การเคลื่อนที่ WASD/Arrow
│   ├── NPC.gd                 ← NPC interaction range
│   ├── HotelInteract.gd       ← Hotel interaction zone
│   ├── WorldMap.gd            ← Placeholder world drawing
│   ├── DialogueUI.gd
│   ├── JobSelectUI.gd
│   ├── JobDescriptionUI.gd
│   ├── HotelPromptUI.gd
│   ├── SleepScene.gd
│   ├── VictoryScene.gd
│   └── LoseScene.gd           ← shared สำหรับ lose scenes ทั้งคู่
│
└── assets/
    ├── README.md              ← วิธีนำ assets มาใส่
    ├── characters/
    │   ├── player/            ← วาง Cyberpunk_City_Character_01.png
    │   └── npc/               ← วาง Cyberpunk_City_Character_02.png
    ├── tilemap/
    │   ├── TILEMAP_SETUP.md   ← วิธีตั้งค่า TileMap
    │   ├── (Cyberpunk_City_Tiles_Fences.png)
    │   ├── (Cyberpunk_City_Props.png)
    │   └── (Cyberpunk_City_Doors_Windows_Signs.png)
    ├── ui/
    │   ├── icons/
    │   │   └── icon.svg
    │   └── buttons/
    └── audio/
```

---

## วิธีเปิดโปรเจกต์

1. เปิด **Godot 4.3** หรือ 4.6
2. Import → เลือก `project.godot`
3. กด Run (F5) — เกมจะเริ่มที่ MainMenu

---

## การนำ Assets มาใส่

### ขั้นตอนง่ายๆ:
1. คัดลอกไฟล์ PNG ไปวางใน folder ที่กำหนด
2. เปิด Godot → FileSystem panel จะ detect อัตโนมัติ
3. เลือก node ที่ต้องการ → Inspector → Texture → ลากไฟล์มาวาง

### Player Sprite:
- เปิด `MainGame.tscn` → เลือก `Player/PlayerSprite`
- ลบ placeholder code ใน `Player.gd` (ส่วน `_draw_placeholder`)
- ลาก `characters/player/player_sheet.png` มาวางที่ Texture

### NPC Sprite:
- เลือก `WorldMap/NPCNode1/NPCSprite1` → ลาก NPC texture
- ทำซ้ำสำหรับ NPCNode2

### TileMap:
- ดู `assets/tilemap/TILEMAP_SETUP.md` สำหรับคำแนะนำละเอียด

### Dialogue Avatar:
- เปิด `DialogueUI.tscn` → เลือก `P1Icon` / `NPCIcon`
- ลาก texture ที่ crop มาจาก sprite sheet

---

## Game Flow

```
MainMenu → IntroScene → MainGame
                            ↓
                    เดินหา NPC (E)
                            ↓
                    DialogueUI → JobSelectUI
                            ↓
                    JobDescriptionUI (save/pay)
                            ↓
                    เดินกลับ Hotel (E)
                            ↓
                    HotelPromptUI → SleepScene
                            ↓
                    วนซ้ำ จนกว่า...
                    Win → VictoryScene
                    Lose → LoseScene
```

---

## Controls

| ปุ่ม | Action |
|------|--------|
| WASD / Arrow | เดิน |
| E | Interact (คุย NPC / พัก Hotel) |
| E | กด skip dialogue |

---

## Game Balance (ค่า default)

| ค่า | Normal |
|-----|--------|
| หนี้เริ่มต้น | $50,000 |
| พลังงาน | 100% |
| จำนวนวัน | 7 วัน |
| ดอกเบี้ยต่อวัน | 5% |
| Recovery | 45-50% |
