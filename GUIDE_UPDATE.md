# The Debt — คู่มืออัปเดตโค้ดและใส่ Assets

---

## ส่วนที่ 1: ไฟล์ที่เปลี่ยนแปลง

### 1.1 ไฟล์ที่อัปเดต (แทนที่ของเดิม)

| ไฟล์ | การเปลี่ยนแปลง |
|------|---------------|
| `scripts/GameManager.gd` | + real-time clock, + money spending functions, + midnight day-skip |
| `scripts/MainGame.gd` | + pause/resume clock, + MoneySpendUI flow, + midnight handler |

### 1.2 ไฟล์ใหม่ที่ต้องสร้าง

| ไฟล์ | หน้าที่ |
|------|---------|
| `scripts/MoneySpendUI.gd` | Script สำหรับ UI เลือกใช้เงิน |
| `scenes/MoneySpendUI.tscn` | Scene สำหรับ UI เลือกใช้เงิน (สร้างใน Godot) |

---

## ส่วนที่ 2: วิธีใส่ Assets ทีละขั้นตอน

### 2.1 วาง PNG ลงในโฟลเดอร์ที่ถูกต้อง

```
the_debt/assets/
├── characters/
│   ├── player/
│   │   └── player_sheet.png     ← วาง Cyberpunk_City_Character_01.png (ตัวผมเหลือง)
│   └── npc/
│       └── npc_01.png           ← วาง Cyberpunk_City_Character_02.png (ตัวชุดแดง)
├── tilemap/
│   ├── tileset_tiles.png        ← วาง Cyberpunk_City_Tiles_Fences.png
│   ├── tileset_props.png        ← วาง Cyberpunk_City_Props.png
│   └── tileset_doors.png        ← วาง Cyberpunk_City_Doors_Windows_Signs.png
└── ui/
    └── icons/
        └── icon.svg             ← มีอยู่แล้ว
```

**ขั้นตอนการ rename:**
```
Cyberpunk_City_Character_01.png  →  assets/characters/player/player_sheet.png
Cyberpunk_City_Character_02.png  →  assets/characters/npc/npc_01.png
Cyberpunk_City_Tiles_Fences.png  →  assets/tilemap/tileset_tiles.png
Cyberpunk_City_Props.png         →  assets/tilemap/tileset_props.png
Cyberpunk_City_Doors_Windows_Signs.png → assets/tilemap/tileset_doors.png
```

### 2.2 ใส่ Player Sprite ใน Godot

1. เปิด `MainGame.tscn`
2. เลือก node `Player`
3. ใน `Player.gd` ลบส่วน `_create_placeholder_sprite()` ออกทั้งหมด
4. ใน Inspector ของ Player → เพิ่ม `AnimatedSprite2D` node ลูก
5. ลาก `player_sheet.png` ไปที่ SpriteFrames
6. ตั้ง Frame Size: **32×48** pixels

**AnimatedSprite2D animations ที่ต้องสร้าง:**

| Animation | Frames (row, column) | FPS |
|-----------|---------------------|-----|
| `idle`    | Row 0, frame 0-1    | 4   |
| `walk_down`  | Row 0, frame 0-3 | 8   |
| `walk_up`    | Row 1, frame 0-3 | 8   |
| `walk_side`  | Row 2, frame 0-3 | 8   |

7. ใน `Player.gd` เพิ่มโค้ดจัดการ animation:

```gdscript
# เพิ่มใน Player.gd
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
    if locked:
        velocity = Vector2.ZERO
        move_and_slide()
        _anim.play("idle")
        return
    var dir := Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    velocity = dir.normalized() * SPEED if dir.length_squared() > 0.0 else Vector2.ZERO
    move_and_slide()

    if velocity.length_squared() > 0.0:
        if abs(velocity.x) > abs(velocity.y):
            _anim.flip_h = velocity.x < 0
            _anim.play("walk_side")
        elif velocity.y > 0:
            _anim.play("walk_down")
        else:
            _anim.play("walk_up")
    else:
        _anim.play("idle")
```

### 2.3 ใส่ NPC Sprite

1. เปิด `MainGame.tscn`
2. เลือก NPC node (อยู่ใน World group)
3. เพิ่ม `Sprite2D` node ลูก
4. ลาก `npc_01.png` → Texture
5. ตั้ง `region_rect` ให้ได้ frame แรก (32×48)

### 2.4 ตั้งค่า TileMap

1. เปิด `MainGame.tscn` → เลือก `WorldMap/TileMap`
2. Inspector → TileSet → **[New TileSet]**
3. เปิด TileSet editor (bottom panel)
4. กด **+** → เลือก `tileset_tiles.png`
5. ตั้ง Tile Size: **16×16**
6. ทำซ้ำสำหรับ `tileset_props.png` และ `tileset_doors.png`
7. วาด map ตามแผนผัง:

```
Layer 0 "background"  : อาคาร / พื้นหลัง
Layer 1 "ground"      : พื้นเดิน sidewalk บน (Y=300-420)
Layer 2 "road"        : ถนน ไม่ walkable (Y=500-620)
Layer 3 "props"       : ป้าย ไฟถนน ของตกแต่ง
```

---

## ส่วนที่ 3: ระบบใหม่ที่เพิ่ม

### 3.1 ระบบเวลาเดินอัตโนมัติ

**ของเดิม:** เวลาจะเปลี่ยนเฉพาะตอนทำงาน  
**ของใหม่:** เวลาเดินเองทุก 2 in-game minutes ต่อ 1 real second

เมื่อเวลาครบ **เที่ยงคืน (00:00)**:
- วันถัดไปเริ่มอัตโนมัติ
- ดอกเบี้ยหนี้บวกเพิ่ม
- **พลังงานไม่เพิ่ม** (ต่างจากการนอนโรงแรม)

โค้ดหลักอยู่ใน `GameManager.gd`:
```gdscript
const MINUTES_PER_REAL_SECOND: float = 2.0  # ปรับความเร็วได้
```

**ปรับความเร็วเวลา:** เปลี่ยนค่า `MINUTES_PER_REAL_SECOND`
- `1.0` = ช้า (1 real min = 1 game min)  
- `2.0` = ปกติ (1 real sec = 2 game min)
- `5.0` = เร็ว (1 real sec = 5 game min)

**เวลาหยุดเดินระหว่าง UI:**  
Clock หยุดอัตโนมัติตอนเปิด Dialogue / Job Select / Hotel Prompt

### 3.2 ระบบใช้เงิน (MoneySpendUI)

หลังทำงานเสร็จแต่ละครั้ง จะมีหน้า **"What will you do with the money?"**

ตัวเลือก:

| ตัวเลือก | ผล |
|---------|-----|
| **Save it** | เก็บเงินไว้, พลังงาน +5% |
| **Pay ALL debt** | จ่ายเงินทั้งหมดลดหนี้, พลังงาน -5% |
| **Pay HALF** | จ่ายครึ่งหนึ่ง เก็บครึ่งหนึ่ง, พลังงาน -5% |
| **Street Noodles** ($30) | พลังงาน +12% |
| **Energy Drink** ($60) | พลังงาน +20% |
| **Protein Pack** ($120) | พลังงาน +35% |
| **Black Market Stim** ($250) | พลังงาน +60% |
| **Keep Working** | กลับไปเลือกงานต่อ (ไม่ได้ใช้เงิน) |

---

## ส่วนที่ 4: วิธีสร้าง MoneySpendUI.tscn ใน Godot

### Node Structure:
```
MoneySpendUI (CanvasLayer)
└── Root (Control, full screen)
    ├── BG (ColorRect, dark semi-transparent)
    └── VBox (VBoxContainer, centered)
        ├── LblJobName (Label, large)
        ├── LblEarned (Label, green)
        ├── LblEvent (Label, hidden by default)
        ├── Divider (HSeparator)
        ├── StatusRow (HBoxContainer)
        │   ├── LblEnergy (Label)
        │   ├── LblCash (Label)
        │   └── LblDebt (Label)
        ├── Choices (VBoxContainer)
        │   ├── BtnSave (Button)
        │   ├── BtnPayAll (Button)
        │   ├── BtnPayHalf (Button)
        │   ├── BtnFood1 (Button)
        │   ├── BtnFood2 (Button)
        │   ├── BtnFood3 (Button)
        │   └── BtnFood4 (Button)
        └── BtnMore (Button)
```

1. ใน Godot สร้าง Scene ใหม่ → root เป็น **CanvasLayer**
2. บันทึกเป็น `scenes/MoneySpendUI.tscn`
3. สร้าง node ตามโครงสร้างด้านบน
4. Attach script `scripts/MoneySpendUI.gd` ที่ root node

---

## ส่วนที่ 5: อัปเดตไฟล์เดิมใน Godot

### 5.1 GameManager.gd
แทนที่ด้วยไฟล์ใหม่ทั้งหมด (อยู่ใน `scripts/GameManager.gd` ของ zip นี้)

### 5.2 MainGame.gd  
แทนที่ด้วยไฟล์ใหม่ทั้งหมด (อยู่ใน `scripts/MainGame.gd` ของ zip นี้)

### 5.3 สร้าง MoneySpendUI.gd และ .tscn
ตามที่อธิบายในส่วนที่ 4

---

## ส่วนที่ 6: สรุประบบ Backward Compatibility

ถ้ายังไม่ได้สร้าง `MoneySpendUI.tscn` เกมจะ **fallback อัตโนมัติ** ไปใช้ `JobDescriptionUI.tscn` เดิม  
(โค้ดใน MainGame.gd ตรวจสอบ `ResourceLoader.exists()` ก่อนเสมอ)

---

## ส่วนที่ 7: Quick Checklist

- [ ] วาง PNG assets ในโฟลเดอร์ที่ถูกต้อง
- [ ] Import เข้า Godot (เปิดโปรเจกต์แล้ว Godot import อัตโนมัติ)
- [ ] แทนที่ `GameManager.gd` ด้วยไฟล์ใหม่
- [ ] แทนที่ `MainGame.gd` ด้วยไฟล์ใหม่
- [ ] ใส่ AnimatedSprite2D ให้ Player
- [ ] ใส่ Sprite2D ให้ NPC
- [ ] ตั้งค่า TileMap (3 tileset sources)
- [ ] สร้าง `MoneySpendUI.tscn` (optional แต่แนะนำ)
- [ ] รัน F5 ทดสอบ

---

## ส่วนที่ 8: คำอธิบาย Signals ใหม่ใน GameManager

```gdscript
signal time_changed   ## emit ทุกครั้งที่นาทีเปลี่ยน → HUD อัปเดตอัตโนมัติ
signal day_changed    ## emit ทั้งตอน rest() และ midnight → MainGame ตรวจ condition
signal money_changed  ## emit ทุกครั้ง money เปลี่ยน → ใช้อัปเดต UI ที่ต้องการ
```
