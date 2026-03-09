# TileMap Setup Guide — The Debt

## การตั้งค่า TileMap ใน Godot 4

### 1. Import Tileset Images
วางไฟล์ทั้งหมดใน `assets/tilemap/`:
- `Cyberpunk_City_Tiles_Fences.png`
- `Cyberpunk_City_Props.png`
- `Cyberpunk_City_Doors_Windows_Signs.png`

### 2. สร้าง TileSet Resource
1. เปิด MainGame.tscn
2. เลือก node `WorldMap/TileMap`
3. ใน Inspector → TileSet → [New TileSet]
4. เปิด TileSet editor (ล่างสุดของ editor)
5. คลิก "+" เพื่อเพิ่ม tileset source
6. ลาก PNG จาก FileSystem มาวาง

### 3. Tile Size
- Tile Size: **16 x 16** pixels (หรือ 32x32 ขึ้นอยู่กับ spritesheet)

### 4. Physics Layers
สร้าง Physics Layer สำหรับ collision:
- Layer 0: Ground (walkable)
- Layer 1: Walls (solid)
- Layer 2: Props (decorative)

### 5. แผนผัง Map (Layout)
```
Y=0-300    : Buildings / Background (Layer 0)
Y=300-420  : Walkable Upper Platform (Layer 1) ← Player walks here
Y=420-500  : Fence / Barrier
Y=500-620  : Road (not walkable)
Y=620-720  : Walkable Lower Sidewalk (Layer 2)
```

### 6. Layers ใน TileMap
- **Layer 0** "background" — sky, building backs
- **Layer 1** "ground" — floor tiles, sidewalk
- **Layer 2** "walls" — building fronts, fences
- **Layer 3** "props" — signs, lights, trash

### 7. Camera Limits
ตั้ง Camera2D limits ใน MainGame.tscn:
- limit_left: 0
- limit_right: 3200
- limit_top: 0
- limit_bottom: 720

### 8. Sprite ตัวละคร
แต่ละ sprite sheet ใช้ **AnimatedSprite2D** หรือ **Sprite2D** กับ **region_rect**:
- Player (Character_01): frame ขนาด 32x48 (ประมาณ)
- NPC (Character_02): frame ขนาด 32x48

### 9. Collision Shape ของ Player
ตั้ง CollisionShape2D ขนาด **24x16** (แค่ขาล่าง) เพื่อให้ player เดินผ่านได้สมจริง
