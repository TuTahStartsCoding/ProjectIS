# Assets Folder — The Debt

วางไฟล์ assets ตามโฟลเดอร์ดังนี้:

## 📁 characters/player/
ไฟล์ spritesheet ของตัวละครผู้เล่น (Character 01 - ผมสีเหลือง)
- `player_sheet.png` — Spritesheet หลัก (ใช้ไฟล์ Cyberpunk_City_Character_01.png)

## 📁 characters/npc/
ไฟล์ spritesheet ของ NPC ต่างๆ
- `npc_01.png` — NPC ตัวที่ 1 (ใช้ไฟล์ Cyberpunk_City_Character_02.png)
- `npc_icon_01.png` — Icon เล็กสำหรับ dialogue box (crop จาก spritesheet)
- `npc_icon_02.png` — Icon เล็กสำหรับ NPC ตัวที่ 2

## 📁 tilemap/
ไฟล์ tileset สำหรับ TileMap ของ Godot
- `tileset_tiles.png` — ใช้ไฟล์ Cyberpunk_City_Tiles_Fences.png
- `tileset_props.png` — ใช้ไฟล์ Cyberpunk_City_Props.png
- `tileset_doors.png` — ใช้ไฟล์ Cyberpunk_City_Doors_Windows_Signs.png

## 📁 ui/icons/
- `icon.svg` — App icon (ใช้ Godot default หรือสร้างใหม่)
- `player_avatar.png` — Avatar ของผู้เล่นในกล่อง dialogue (crop มาจาก player sprite)
- `npc_avatar_01.png` — Avatar NPC 1 ใน dialogue
- `npc_avatar_02.png` — Avatar NPC 2 ใน dialogue

## 📁 ui/buttons/
ไฟล์รูปสำหรับปุ่มต่างๆ (optional ถ้าต้องการ custom style)

## 📁 audio/
- `bgm_main.ogg` — เพลงพื้นหลัง
- `sfx_click.ogg` — เสียงคลิก
- `sfx_work.ogg` — เสียงทำงาน
- `sfx_sleep.ogg` — เสียงนอน

## วิธีใส่ Sprites ใน Godot:
1. เปิด Godot 4 แล้ว import project.godot
2. ลาก PNG ไปวางใน FileSystem panel
3. เปิด MainGame.tscn → เลือก PlayerSprite → ลาก texture จาก FileSystem
4. ทำเช่นเดียวกันกับ NPCSprite1, NPCSprite2, HotelSprite
5. สำหรับ TileMap → สร้าง TileSet ใหม่ใน Inspector แล้ว import png เป็น tiles
