extends Node
## GameManager — Global Autoload Singleton
## 50 jobs with 2-3 events each, real-time clock, money spending system

signal time_changed
signal day_changed
signal money_changed

var energy: float = 100.0
var max_energy: float = 100.0
var debt_remaining: float = 6000.0
var debt_paid: float = 0.0
var total_debt: float = 6000.0
var money: float = 0.0
var current_day: int = 1
var max_days: int = 7
var current_hour: int = 8
var current_minute: int = 0
var sound_effect_volume: float = 0.5
var music_volume: float = 0.5
var brightness: float = 0.5
var game_difficulty: String = "normal"
var debt_interest_rate: float = 0.05
var daily_money_earned: float = 0.0
var daily_debt_paid: float = 0.0
var daily_energy_used: float = 0.0
var daily_events: Array[String] = []
var jobs_done_today: int = 0
var _today_job_ids: Array[int] = []
var _used_job_ids_today: Array[int] = []
var _prev_day_job_ids: Array[int] = []

const MINUTES_PER_REAL_SECOND: float = 2.0
var _time_accumulator: float = 0.0
var _clock_running: bool = true

var food_items: Array[Dictionary] = [
	{ "name": "ข้าวเหนียวหมูปิ้ง",    "cost": 30,  "energy": 12.0, "desc": "ราคาถูก อิ่มท้อง" },
	{ "name": "เครื่องดื่มชูกำลัง",    "cost": 60,  "energy": 20.0, "desc": "พลังงานสังเคราะห์" },
	{ "name": "โปรตีนแพ็ค",           "cost": 120, "energy": 35.0, "desc": "โภชนาการสูง" },
	{ "name": "ยากระตุ้น (ตลาดมืด)", "cost": 250, "energy": 60.0, "desc": "ผิดกฎหมาย แต่ได้ผล" },
]

## ── 50 JOBS ─────────────────────────────────────────────────────────────────
## แต่ละงานมี events: Array of {desc, text_color, money_mod, energy_mod}
## ระบบจะสุ่ม 1 event ต่องาน (45% โอกาส)
var all_jobs: Array[Dictionary] = [
	## ─── กลุ่มแรงงาน ───
	{ "id":  1, "name": "แบกของท่าเรือ",       "reward": 1000, "energy_cost": 40, "hours": 10,
	  "desc": "ขนตู้คอนเทนเนอร์ที่ท่าเรือ งานหนักแต่จ่ายดี",
	  "flavor": "หัวหน้างานตะโกนสั่งไม่หยุด หลังเริ่มปวดตั้งแต่ชั่วโมงที่สาม แต่มือยังยกต่อไปได้",
	  "events": [
		{ "desc": "เพื่อนร่วมงานช่วยแบกส่วนหนักแทน ทำให้เสร็จเร็วกว่ากำหนด", "text_color": "green", "money_mod": 0, "energy_mod": 10 },
		{ "desc": "ของตกใส่เท้า ปวดตลอดชั่วโมงที่เหลือ แต่ไม่หยุด", "text_color": "red", "money_mod": 0, "energy_mod": -15 },
		{ "desc": "เจ้าของท่าพอใจงาน ให้โบนัสพิเศษ", "text_color": "green", "money_mod": 200, "energy_mod": 0 },
	  ] },
	{ "id":  2, "name": "ส่งพัสดุด่วน",         "reward": 220, "energy_cost": 15, "hours": 2,
	  "desc": "ส่งกล่องปิดผนึก ไม่ต้องถามว่ามีอะไรข้างใน",
	  "flavor": "พัสดุใบที่ 7 อุ่นผิดปกติ ไม่ถาม ทิปที่ปลายทางเย็นและเป็นเงินสด",
	  "events": [
		{ "desc": "ที่อยู่ผิด ต้องย้อนทางสองรอบ เสียเวลาแต่ยังส่งได้", "text_color": "red", "money_mod": 0, "energy_mod": -5 },
		{ "desc": "ลูกค้าประทับใจความตรงต่อเวลา ให้ทิปพิเศษ", "text_color": "green", "money_mod": 80, "energy_mod": 0 },
		{ "desc": "ถูกตำรวจหยุดตรวจ รอนาน 20 นาที", "text_color": "red", "money_mod": 0, "energy_mod": -4 },
	  ] },
	{ "id":  3, "name": "ขายก๋วยเตี๋ยวริมทาง", "reward": 65, "energy_cost": 8, "hours": 1,
	  "desc": "ขายก๋วยเตี๋ยวมุมถนน เล็กน้อยแต่สุจริต",
	  "flavor": "ไอน้ำลอยขึ้นมาปะทะหน้า คนสูทแวะซื้อแล้วทอดเงินทิ้งไว้โดยไม่มอง",
	  "events": [
		{ "desc": "ฝนตกกะทันหัน ลูกค้าน้อยกว่าปกติมาก", "text_color": "red", "money_mod": -25, "energy_mod": 0 },
		{ "desc": "ลูกค้าประจำแวะมา ซื้อเยอะกว่าปกติเพราะชอบฝีมือ", "text_color": "green", "money_mod": 40, "energy_mod": 0 },
	  ] },
	{ "id":  4, "name": "พิมพ์ข้อมูลบริษัท",    "reward": 380, "energy_cost": 20, "hours": 4,
	  "desc": "งานออฟฟิศ ตัวเลขและความเงียบ",
	  "flavor": "แสงจอทำให้ตาแสบตั้งแต่ชั่วโมงที่สอง ระบบเตือนว่าเข้าห้องน้ำเกินเวลา",
	  "events": [
		{ "desc": "ระบบล่ม ต้องทำงานซ้ำบางส่วน พลังงานเพิ่มหาย", "text_color": "red", "money_mod": 0, "energy_mod": -8 },
		{ "desc": "หัวหน้าพอใจงาน เพิ่มค่าแรงในสลิป", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "เพื่อนร่วมงานสอนลัดทำให้เสร็จเร็ว", "text_color": "green", "money_mod": 0, "energy_mod": 7 },
	  ] },
	{ "id":  5, "name": "รปภ.กลางคืน",          "reward": 500, "energy_cost": 28, "hours": 6,
	  "desc": "เฝ้าโกดังในความมืด",
	  "flavor": "ชั่วโมงที่สาม มีเสียงฝีเท้าที่หยุดกะทันหัน ชั่วโมงที่ห้า มีประตูเปิดเอง",
	  "events": [
		{ "desc": "พบคนบุกรุก ไล่ออกไปได้ เจ้าของให้โบนัสพิเศษ", "text_color": "green", "money_mod": 150, "energy_mod": -5 },
		{ "desc": "นั่งเฝ้าจนเกือบหลับ แต่ยึดสติอยู่ได้ตลอด", "text_color": "white", "money_mod": 0, "energy_mod": -6 },
		{ "desc": "ค้นพบสินค้าที่หายไปในโกดัง เจ้าของดีใจมาก", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
	  ] },
	{ "id":  6, "name": "ชกมวยใต้ดิน",          "reward": 2200, "energy_cost": 60, "hours": 2,
	  "desc": "หนึ่งแมตช์ เงินสูงสุด ความเสียหายสูงสุด",
	  "flavor": "กลิ่นเหงื่อและเงินตราลอยอยู่ในอากาศ คู่ต่อสู้ตัวใหญ่กว่า แต่ชนะได้",
	  "events": [
		{ "desc": "คู่ต่อสู้ถนัดซ้าย โดนชกตรงจุดอ่อนก่อนจะปรับตัวได้", "text_color": "red", "money_mod": 0, "energy_mod": -18 },
		{ "desc": "ฝูงชนโห่ให้กำลังใจ ทำให้ได้รับแรงกระตุ้นพิเศษ", "text_color": "green", "money_mod": 300, "energy_mod": 0 },
		{ "desc": "ชนะเร็วกว่าที่คาด ร่างกายเสียหายน้อยกว่าปกติ", "text_color": "green", "money_mod": 0, "energy_mod": 15 },
	  ] },
	{ "id":  7, "name": "ซ่อมอิมแพลนต์",        "reward": 300, "energy_cost": 14, "hours": 3,
	  "desc": "ซ่อมอิมแพลนต์และวงจรไฟฟ้า",
	  "flavor": "ควันบัดกรีลอยหนาแน่น แจ็คประสาทของลูกค้าระเบิดประกายไฟ แก้ปัญหาด้วยเข็มหมุดโก่ง",
	  "events": [
		{ "desc": "อิมแพลนต์ซับซ้อนกว่าที่คิด ต้องใช้เวลาและสมาธิมากขึ้น", "text_color": "red", "money_mod": 0, "energy_mod": -8 },
		{ "desc": "ลูกค้าบอกปากต่อปาก มีลูกค้าใหม่ฝากบอกว่าจะมาอีก", "text_color": "green", "money_mod": 80, "energy_mod": 0 },
	  ] },
	{ "id":  8, "name": "ขนของตลาดมืด",         "reward": 750, "energy_cost": 26, "hours": 3,
	  "desc": "ลักลอบขนสินค้าผ่านด่านตรวจ",
	  "flavor": "สามด่านตรวจ สองครั้งที่ต้องจ่ายสินบน เซ็นเซอร์หนึ่งตัวที่เกือบจับได้",
	  "events": [
		{ "desc": "ด่านเพิ่มขึ้นกะทันหัน ต้องอ้อมทางพิเศษ เสียเวลาและพลังงาน", "text_color": "red", "money_mod": -100, "energy_mod": -8 },
		{ "desc": "ตำรวจที่ด่านเป็นคนรู้จัก เดินผ่านได้โดยไม่ต้องจ่าย", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "ลูกค้าปลายทางพอใจมาก จ่ายโบนัสพิเศษ", "text_color": "green", "money_mod": 200, "energy_mod": 0 },
	  ] },
	{ "id":  9, "name": "งานก่อสร้าง",           "reward": 720, "energy_cost": 36, "hours": 8,
	  "desc": "เทคอนกรีตกลางแดดร้อน ความเหนื่อยที่สุจริต",
	  "flavor": "หัวหน้างานพูดคนละภาษา แต่ภาษาแห่งงานนั้นสากล ยก เท ทำซ้ำ",
	  "events": [
		{ "desc": "แดดจัดมาก อุณหภูมิสูงกว่าปกติ ร่างกายสูญเสียน้ำเยอะ", "text_color": "red", "money_mod": 0, "energy_mod": -12 },
		{ "desc": "ฝนตกช่วยคลายร้อน ทำงานได้ดีขึ้นในช่วงหลัง", "text_color": "green", "money_mod": 0, "energy_mod": 8 },
		{ "desc": "ทีมงานช่วยกันเสร็จเร็วกว่ากำหนด หัวหน้าให้โบนัสทีม", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
	  ] },
	{ "id": 10, "name": "เล่นดนตรีข้างทาง",     "reward": 90, "energy_cost": 10, "hours": 2,
	  "desc": "เล่นดนตรีบนชานชาลารถไฟ",
	  "flavor": "สามคนแวะฟัง หนึ่งคนเมา เด็กหญิงฟังด้วยทั้งตัวทั้งใจ แต่ไม่ให้ทิป",
	  "events": [
		{ "desc": "นักดนตรีอีกคนมาเล่นแข่ง แต่ฝูงชนชอบเราเสียงมากกว่า", "text_color": "green", "money_mod": 60, "energy_mod": 0 },
		{ "desc": "รปภ.สถานีไล่ออกกลางคัน เสียรายได้ส่วนหนึ่ง", "text_color": "red", "money_mod": -30, "energy_mod": -3 },
	  ] },
	## ─── กลุ่มบริการ ───
	{ "id": 11, "name": "ช่วยทวงหนี้",           "reward": 580, "energy_cost": 22, "hours": 3,
	  "desc": "ช่วยคนอื่นเรียกเก็บหนี้ ศีลธรรมพอรับได้",
	  "flavor": "เคาะประตูห้าบาน สองบานเปิด หนึ่งบานร้องไห้ รับเงินแล้วเดินกลับ",
	  "events": [
		{ "desc": "ลูกหนี้ต่อสู้ขัดขืน ต้องใช้แรงมากกว่าปกติ", "text_color": "red", "money_mod": 0, "energy_mod": -10 },
		{ "desc": "ลูกหนี้ยอมจ่ายหมดทันที หัวหน้าให้โบนัสสำหรับงานที่ราบรื่น", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
		{ "desc": "ลูกหนี้ขอผ่อนชำระ นายจ้างพอใจที่เจรจาได้", "text_color": "white", "money_mod": 50, "energy_mod": 0 },
	  ] },
	{ "id": 12, "name": "เก็บกวาดสารพิษ",        "reward": 860, "energy_cost": 38, "hours": 5,
	  "desc": "ทำความสะอาดพื้นที่อันตราย มีชุดป้องกันให้",
	  "flavor": "ชุดป้องกันเล็กเกินไปหน่อย กลิ่นยังเล็ดลอดเข้ามา ค่าตอบแทนพิเศษพอจะลืม",
	  "events": [
		{ "desc": "ชุดป้องกันรั่ว ต้องหยุดงานซ่อมก่อน เสียเวลาและพลังงาน", "text_color": "red", "money_mod": 0, "energy_mod": -12 },
		{ "desc": "งานเสร็จเร็วกว่ากำหนด ผู้ว่าจ้างพอใจมาก", "text_color": "green", "money_mod": 200, "energy_mod": 5 },
	  ] },
	{ "id": 13, "name": "คุ้มกัน VIP",           "reward": 1400, "energy_cost": 32, "hours": 6,
	  "desc": "ดูแลผู้บริหารบริษัท ความเสี่ยงสูง",
	  "flavor": "เขาพูดตลอดเรื่องสินทรัพย์และซินเนอจี มีคนพยายามตาม หลบเข้าซอกตลาดได้",
	  "events": [
		{ "desc": "มีคนพยายามเข้าใกล้ VIP ต้องใช้ร่างกายปิดกั้น", "text_color": "red", "money_mod": 0, "energy_mod": -15 },
		{ "desc": "VIP ประทับใจมาก ให้ทิปส่วนตัวเพิ่มจากค่าจ้าง", "text_color": "green", "money_mod": 400, "energy_mod": 0 },
		{ "desc": "เส้นทางราบรื่น งานจบก่อนเวลา", "text_color": "green", "money_mod": 0, "energy_mod": 10 },
	  ] },
	{ "id": 14, "name": "คัดแยกเศษเหล็ก",        "reward": 160, "energy_cost": 18, "hours": 3,
	  "desc": "หาชิ้นส่วนจากกองขยะอุตสาหกรรม",
	  "flavor": "พบชิปหน่วยความจำที่ยังใช้งานได้ในกองตะกรัน ขายให้คนแรกที่พบ",
	  "events": [
		{ "desc": "พบชิ้นส่วนหายากที่มีมูลค่าสูง ขายได้ราคาดีมาก", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
		{ "desc": "โดนแก้วแตกบาด ต้องพักผ่อนระยะสั้น", "text_color": "red", "money_mod": 0, "energy_mod": -8 },
	  ] },
	{ "id": 15, "name": "ล้างจาน",               "reward": 120, "energy_cost": 12, "hours": 2,
	  "desc": "ล้างจานร้านอาหารหรูย่านบน",
	  "flavor": "มือแช่น้ำร้อนสี่ชั่วโมง แต่ร้านนี้ให้ข้าวฟรีพนักงาน",
	  "events": [
		{ "desc": "เชฟให้อาหารพิเศษหลังงาน ฟื้นพลังงานได้บ้าง", "text_color": "green", "money_mod": 0, "energy_mod": 12 },
		{ "desc": "จานแตก หักค่าจ้างส่วนหนึ่ง", "text_color": "red", "money_mod": -40, "energy_mod": 0 },
		{ "desc": "ลูกค้าหรูทิ้งทิปให้พนักงานครัว", "text_color": "green", "money_mod": 60, "energy_mod": 0 },
	  ] },
	{ "id": 16, "name": "รับจ้างทำความสะอาด",   "reward": 180, "energy_cost": 16, "hours": 3,
	  "desc": "ทำความสะอาดอาคารสำนักงาน",
	  "flavor": "กุญแจทุกชั้นอยู่ในมือ ห้องที่ล็อคอยู่น่าสนใจ แต่เราไม่ใช่คนแบบนั้น",
	  "events": [
		{ "desc": "พบกระเป๋าเงินที่ลืมไว้ ส่งคืนเจ้าของ ได้รับรางวัล", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "สารเคมีทำความสะอาดทำให้หายใจลำบาก", "text_color": "red", "money_mod": 0, "energy_mod": -7 },
	  ] },
	{ "id": 17, "name": "แบกของในตลาด",          "reward": 95, "energy_cost": 11, "hours": 1,
	  "desc": "ช่วยพ่อค้าแม่ค้าแบกสินค้า",
	  "flavor": "ตลาดวุ่นวาย เสียงดัง กลิ่นปะปน ทุกคนเร่งรีบ",
	  "events": [
		{ "desc": "พ่อค้าแม่ค้าใจดี แบ่งอาหารให้กิน", "text_color": "green", "money_mod": 0, "energy_mod": 8 },
		{ "desc": "ของหนักกว่าที่บอก หลังเริ่มปวด", "text_color": "red", "money_mod": 0, "energy_mod": -5 },
	  ] },
	{ "id": 18, "name": "จ้างเป็นนักแสดงประกอบ", "reward": 200, "energy_cost": 10, "hours": 2,
	  "desc": "นักแสดงประกอบในโฆษณา ต้องอยู่นิ่งนาน",
	  "flavor": "ยืนนิ่งสองชั่วโมงภายใต้ไฟส่องสว่างร้อนๆ แต่จ่ายดีกว่าที่คิด",
	  "events": [
		{ "desc": "ผู้กำกับพอใจ ขอถ่ายเพิ่ม จ่ายโอที", "text_color": "green", "money_mod": 80, "energy_mod": -4 },
		{ "desc": "ถ่ายได้ในรอบเดียว เสร็จเร็ว", "text_color": "green", "money_mod": 0, "energy_mod": 5 },
	  ] },
	{ "id": 19, "name": "รับส่งผู้โดยสาร",       "reward": 280, "energy_cost": 18, "hours": 4,
	  "desc": "ขับรถรับจ้างในย่านกลางคืน",
	  "flavor": "ผู้โดยสารแต่ละคนพาความลับของตัวเองมาด้วย ไม่มีใครพูดก่อน",
	  "events": [
		{ "desc": "ผู้โดยสารฝากเพิ่มหลังจากสนทนาระหว่างทาง", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "รถติดมาก ใช้เวลานานกว่าที่ควร", "text_color": "red", "money_mod": -30, "energy_mod": -6 },
		{ "desc": "ผู้โดยสารคนหนึ่งแนะนำงานพิเศษให้ในอนาคต", "text_color": "white", "money_mod": 60, "energy_mod": 0 },
	  ] },
	{ "id": 20, "name": "ดูแลเด็กชั่วคราว",      "reward": 150, "energy_cost": 8, "hours": 2,
	  "desc": "ดูแลเด็กให้ผู้ปกครองที่ไม่มีเวลา",
	  "flavor": "เด็กถามคำถามที่ตอบยากที่สุดในชีวิต ทำไมคนถึงต้องทำงานตลอด",
	  "events": [
		{ "desc": "เด็กหลับเร็ว งานง่ายกว่าที่คิด มีเวลาพักด้วย", "text_color": "green", "money_mod": 0, "energy_mod": 5 },
		{ "desc": "เด็กซุกซน วิ่งหนีออกไป ต้องตามหาเกือบครึ่งชั่วโมง", "text_color": "red", "money_mod": 0, "energy_mod": -8 },
	  ] },
	## ─── กลุ่มเทคโนโลยี ───
	{ "id": 21, "name": "ซ่อมคอมพิวเตอร์",       "reward": 250, "energy_cost": 12, "hours": 2,
	  "desc": "ซ่อมเครื่องคอมพิวเตอร์ในบ้าน",
	  "flavor": "ไฟล์ที่ลูกค้าลืมลบบอกเรื่องราวมากกว่าที่ควรรู้ ทำเป็นไม่เห็น",
	  "events": [
		{ "desc": "ปัญหาง่ายกว่าที่คิด เสร็จเร็ว ลูกค้าจ่ายเต็ม", "text_color": "green", "money_mod": 0, "energy_mod": 5 },
		{ "desc": "เครื่องพังหนักกว่าคาด ต้องใช้เวลาและทักษะมากขึ้น", "text_color": "red", "money_mod": -30, "energy_mod": -5 },
	  ] },
	{ "id": 22, "name": "ติดตั้งกล้องวงจรปิด",   "reward": 320, "energy_cost": 15, "hours": 3,
	  "desc": "ติดตั้งระบบกล้องรักษาความปลอดภัย",
	  "flavor": "หลังงานเสร็จ ฉันรู้ว่าเจ้าของดูกล้องอยู่ตลอดเวลา รู้สึกอึดอัดแปลกๆ",
	  "events": [
		{ "desc": "ระบบซับซ้อนกว่าที่คิด ต้องใช้เวลาเพิ่ม แต่ได้ค่าแรงพิเศษ", "text_color": "green", "money_mod": 80, "energy_mod": -5 },
		{ "desc": "อุปกรณ์บกพร่อง ต้องซื้อชิ้นส่วนเพิ่มเอง", "text_color": "red", "money_mod": -60, "energy_mod": 0 },
	  ] },
	{ "id": 23, "name": "เขียนโค้ดจ้าง",         "reward": 450, "energy_cost": 18, "hours": 4,
	  "desc": "เขียนโปรแกรมให้บริษัทย่อม",
	  "flavor": "โค้ดที่ขอมามันทำอะไรบางอย่างที่ไม่ควรทำ ทำเสร็จแล้วไม่ถามต่อ",
	  "events": [
		{ "desc": "ลูกค้าพอใจงาน ให้เรตติ้งดี มีงานใหม่ติดตามมา", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
		{ "desc": "Requirement เปลี่ยนกลางคัน ต้องทำใหม่บางส่วน", "text_color": "red", "money_mod": 0, "energy_mod": -8 },
		{ "desc": "เจอ bug ที่แก้ยาก นั่งแก้จนดึก แต่รู้สึกดีที่แก้ได้", "text_color": "white", "money_mod": 50, "energy_mod": -5 },
	  ] },
	{ "id": 24, "name": "ซ่อมโดรน",              "reward": 380, "energy_cost": 16, "hours": 3,
	  "desc": "ซ่อมโดรนที่เจ้าของทำตก",
	  "flavor": "โดรนนี้มีอุปกรณ์พิเศษที่ไม่ควรมีบนโดรนทั่วไป ซ่อมเสร็จแล้วลืมไป",
	  "events": [
		{ "desc": "ชิ้นส่วนยากหา ต้องสั่งจากตลาดมืด เสียเงินบางส่วน", "text_color": "red", "money_mod": -70, "energy_mod": 0 },
		{ "desc": "เจ้าของโดรนพอใจมาก แนะนำให้เพื่อนหลายคน", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
	  ] },
	{ "id": 25, "name": "ดูแลระบบเซิร์ฟเวอร์",  "reward": 520, "energy_cost": 20, "hours": 5,
	  "desc": "ดูแลเซิร์ฟเวอร์ให้บริษัทตลอดคืน",
	  "flavor": "ข้อมูลที่ผ่านเซิร์ฟเวอร์นี้ทำให้เข้าใจว่าทำไมบริษัทนี้รวยได้เร็วขนาดนี้",
	  "events": [
		{ "desc": "ระบบล่มตอนดึก แก้ปัญหาได้ก่อนที่ข้อมูลจะสูญหาย ได้โบนัส", "text_color": "green", "money_mod": 200, "energy_mod": -10 },
		{ "desc": "คืนสงบ ไม่มีปัญหา นั่งเฝ้าโดยเปล่าประโยชน์", "text_color": "white", "money_mod": 0, "energy_mod": -5 },
		{ "desc": "พบช่องโหว่ความปลอดภัย รายงานให้บริษัทรู้ ได้รางวัลเพิ่ม", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
	  ] },
	## ─── กลุ่มอันตราย/ผิดกฎหมาย ───
	{ "id": 26, "name": "ลักลอบนำเข้าสินค้า",   "reward": 900, "energy_cost": 30, "hours": 4,
	  "desc": "ลักลอบนำสินค้าเข้าเมืองทางด่านลับ",
	  "flavor": "ทางด่านลับนี้รู้จักกันในหมู่คนที่ต้องรู้ มืดและเงียบตลอดเส้นทาง",
	  "events": [
		{ "desc": "ด่านลับถูกจับตาดูมากขึ้น ต้องเสียสินบนเพิ่ม", "text_color": "red", "money_mod": -150, "energy_mod": -5 },
		{ "desc": "ได้รับการแนะนำเส้นทางใหม่ที่ปลอดภัยกว่า งานราบรื่น", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
		{ "desc": "สินค้าหนักกว่าที่บอก แต่ยังแบกได้", "text_color": "red", "money_mod": 0, "energy_mod": -10 },
	  ] },
	{ "id": 27, "name": "ทำงานให้เจ้าหนี้",      "reward": 650, "energy_cost": 24, "hours": 3,
	  "desc": "รับงานจากเจ้าหนี้เพื่อลดหนี้บางส่วน",
	  "flavor": "ทำงานให้คนที่เธอเป็นหนี้อยู่ มันรู้สึกแปลกๆ แต่ก็ยังดีกว่าไม่ได้เงิน",
	  "events": [
		{ "desc": "เจ้าหนี้พอใจ ลดหนี้ให้พิเศษนอกเหนือจากค่าจ้าง", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "เจ้าหนี้เพิ่มงานกลางคัน ต้องทำมากกว่าที่ตกลงไว้", "text_color": "red", "money_mod": 0, "energy_mod": -10 },
	  ] },
	{ "id": 28, "name": "สอดแนมให้จ้าง",         "reward": 800, "energy_cost": 22, "hours": 4,
	  "desc": "ติดตามและรายงานการเคลื่อนไหวของเป้าหมาย",
	  "flavor": "เป้าหมายกินข้าวคนเดียวทุกวัน มองออกไปนอกหน้าต่างบ่อยๆ เหมือนรู้ว่ามีคนดูอยู่",
	  "events": [
		{ "desc": "เป้าหมายเปลี่ยนเส้นทางกะทันหัน ต้องวิ่งตาม", "text_color": "red", "money_mod": 0, "energy_mod": -12 },
		{ "desc": "ได้ข้อมูลสำคัญที่ผู้ว่าจ้างต้องการ โบนัสพิเศษ", "text_color": "green", "money_mod": 250, "energy_mod": 0 },
		{ "desc": "เป้าหมายไม่ทำอะไรน่าสนใจ รายงานเปล่า ได้แค่ค่าจ้างปกติ", "text_color": "white", "money_mod": 0, "energy_mod": 0 },
	  ] },
	{ "id": 29, "name": "ขนยาเถื่อน",            "reward": 1100, "energy_cost": 35, "hours": 3,
	  "desc": "ขนสินค้าต้องห้ามผ่านย่านที่ควบคุม",
	  "flavor": "กล่องเล็กที่แลกด้วยความเสี่ยงสูง เส้นทางนี้คนเดินน้อย นั่นเป็นทั้งข้อดีและข้อเสีย",
	  "events": [
		{ "desc": "เส้นทางถูกปิด ต้องอ้อมไกล เหนื่อยกว่าปกติมาก", "text_color": "red", "money_mod": 0, "energy_mod": -15 },
		{ "desc": "ผ่านไปได้อย่างราบรื่น ผู้รับพอใจ โบนัส", "text_color": "green", "money_mod": 300, "energy_mod": 0 },
	  ] },
	{ "id": 30, "name": "ยามคุมฝูงชน",           "reward": 420, "energy_cost": 25, "hours": 4,
	  "desc": "ดูแลความปลอดภัยในงานใต้ดิน",
	  "flavor": "ฝูงชนเมาและตื่นเต้น ทุกคนดูเหมือนกำลังรอเหตุการณ์บางอย่างจะเกิดขึ้น",
	  "events": [
		{ "desc": "เกิดทะเลาะวิวาทเล็กน้อย หยุดได้ก่อนบานปลาย ได้รับคำชม", "text_color": "green", "money_mod": 80, "energy_mod": -8 },
		{ "desc": "ทะเลาะวิวาทใหญ่ ต้องใช้แรงมาก แต่สงบลงได้", "text_color": "red", "money_mod": 50, "energy_mod": -15 },
		{ "desc": "คืนสงบ ทุกคนสนุกสนาน ได้นั่งดูการแสดงฟรีด้วย", "text_color": "white", "money_mod": 0, "energy_mod": 0 },
	  ] },
	## ─── กลุ่มทักษะพิเศษ ───
	{ "id": 31, "name": "สอนพิเศษ",              "reward": 300, "energy_cost": 12, "hours": 2,
	  "desc": "สอนพิเศษให้เด็กในย่าน",
	  "flavor": "เด็กเรียนรู้เร็วกว่าที่คิด บางทีการสอนผู้อื่นทำให้เราเรียนรู้ตัวเองด้วย",
	  "events": [
		{ "desc": "เด็กเข้าใจบทเรียนได้ดีมาก ผู้ปกครองจ่ายโบนัสพิเศษ", "text_color": "green", "money_mod": 80, "energy_mod": 0 },
		{ "desc": "เด็กงอแง ต้องใช้ความอดทนมาก", "text_color": "red", "money_mod": 0, "energy_mod": -6 },
	  ] },
	{ "id": 32, "name": "แปลภาษา",               "reward": 260, "energy_cost": 10, "hours": 2,
	  "desc": "แปลเอกสารหรือล่ามในการประชุม",
	  "flavor": "สิ่งที่ถูกพูดในห้องนี้ไม่ควรออกไปข้างนอก นั่นคือส่วนหนึ่งของค่าจ้าง",
	  "events": [
		{ "desc": "เอกสารซับซ้อนมาก ต้องใช้สมาธิสูง แต่ได้ค่าแรงเพิ่ม", "text_color": "green", "money_mod": 70, "energy_mod": -5 },
		{ "desc": "ล่ามงานราบรื่น ทั้งสองฝ่ายพอใจ", "text_color": "white", "money_mod": 40, "energy_mod": 0 },
	  ] },
	{ "id": 33, "name": "ถ่ายภาพ",               "reward": 340, "energy_cost": 14, "hours": 3,
	  "desc": "ถ่ายภาพงานหรือบุคคลตามสั่ง",
	  "flavor": "บางรูปที่ถ่ายมาไม่ควรนำไปเผยแพร่ ค่าจ้างรวม 'ค่าลืม' ไว้แล้ว",
	  "events": [
		{ "desc": "แสงดีมาก รูปออกมาสวยงาม ลูกค้าพอใจมาก", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
		{ "desc": "กล้องมีปัญหา ต้องแก้ปัญหากลางงาน", "text_color": "red", "money_mod": -50, "energy_mod": -5 },
	  ] },
	{ "id": 34, "name": "ทำอาหารส่ง",            "reward": 190, "energy_cost": 13, "hours": 2,
	  "desc": "ทำอาหารส่งให้ลูกค้าที่บ้าน",
	  "flavor": "สูตรอาหารที่ลูกค้าขอทำให้รู้ว่าเขากำลังนัดพบใครสักคนที่สำคัญ",
	  "events": [
		{ "desc": "ลูกค้าให้คำชมและสั่งซ้ำทันที โบนัสเล็กน้อย", "text_color": "green", "money_mod": 50, "energy_mod": 0 },
		{ "desc": "วัตถุดิบไม่ตรงสเปค ต้องดัดแปลงสูตร", "text_color": "white", "money_mod": 0, "energy_mod": -4 },
	  ] },
	{ "id": 35, "name": "ตัดผม",                  "reward": 140, "energy_cost": 8, "hours": 1,
	  "desc": "ตัดผมให้ลูกค้าตามบ้านหรือในย่าน",
	  "flavor": "คนที่นั่งตัดผมมักพูดความจริงมากกว่าตอนอื่น",
	  "events": [
		{ "desc": "ลูกค้าพอใจมาก แนะนำให้เพื่อนหลายคน มีลูกค้าใหม่รออยู่", "text_color": "green", "money_mod": 60, "energy_mod": 0 },
		{ "desc": "ลูกค้าไม่พอใจทรงที่ตัดให้ เถียงนาน แต่ก็จ่ายในที่สุด", "text_color": "red", "money_mod": -20, "energy_mod": -3 },
	  ] },
	## ─── กลุ่มขายของ/ค้าขาย ───
	{ "id": 36, "name": "ขายของออนไลน์",         "reward": 220, "energy_cost": 10, "hours": 2,
	  "desc": "ขายของมือสองออนไลน์",
	  "flavor": "ของที่ขายมาจากการรื้อบ้านเก่า ทุกชิ้นมีประวัติที่ไม่รู้ว่าจะทำให้ดีใจหรือเสียใจที่ขาย",
	  "events": [
		{ "desc": "ของชิ้นหนึ่งกลายเป็นของหายาก ขายได้ราคาสูงกว่าที่คาด", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
		{ "desc": "ผู้ซื้อขอคืนของ เสียเวลาและค่าส่ง", "text_color": "red", "money_mod": -60, "energy_mod": -3 },
	  ] },
	{ "id": 37, "name": "ขายอาหารข้างถนน",       "reward": 170, "energy_cost": 14, "hours": 3,
	  "desc": "ขายอาหารในรถเข็นข้างถนนย่านสำนักงาน",
	  "flavor": "มนุษย์ออฟฟิศทุกคนดูเหนื่อยเหมือนกัน ต่างกันแค่สูทแพงกว่า",
	  "events": [
		{ "desc": "วันนี้คนออฟฟิศพักเที่ยงพร้อมกัน คิวยาวมาก ขายได้เยอะ", "text_color": "green", "money_mod": 80, "energy_mod": 0 },
		{ "desc": "เทศกิจมา ต้องย้ายจุด เสียเวลาและลูกค้า", "text_color": "red", "money_mod": -50, "energy_mod": -5 },
		{ "desc": "ลูกค้าประจำแวะมา บอกว่าอาหารดีขึ้นมาก", "text_color": "green", "money_mod": 40, "energy_mod": 4 },
	  ] },
	{ "id": 38, "name": "เป็นนายหน้าขายที่ดิน",  "reward": 680, "energy_cost": 20, "hours": 4,
	  "desc": "ช่วยนายหน้าอสังหาริมทรัพย์หาลูกค้า",
	  "flavor": "ที่ดินชิ้นนี้มีประวัติที่ฉันไม่ได้บอกลูกค้า งานนี้สอนว่าความเงียบก็มีราคา",
	  "events": [
		{ "desc": "ปิดดีลได้ ได้ค่าคอมมิชชั่นพิเศษ", "text_color": "green", "money_mod": 200, "energy_mod": 0 },
		{ "desc": "ลูกค้าไม่ตัดสินใจ เสียเวลาเปล่า", "text_color": "red", "money_mod": -80, "energy_mod": -6 },
	  ] },
	{ "id": 39, "name": "รับซื้อของเก่า",         "reward": 130, "energy_cost": 9, "hours": 1,
	  "desc": "รับซื้อของมือสองและขายต่อ",
	  "flavor": "ของเก่าแต่ละชิ้นมีเรื่องราว บางชิ้นมีคราบน้ำตา บางชิ้นมีคราบเลือด ไม่ถาม",
	  "events": [
		{ "desc": "พบของมีค่าซ่อนอยู่ในของเก่า กำไรเพิ่มมาก", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
		{ "desc": "ของที่รับซื้อมาไม่มีคนซื้อต่อ ขาดทุนนิดหน่อย", "text_color": "red", "money_mod": -40, "energy_mod": 0 },
	  ] },
	{ "id": 40, "name": "ขายข้อมูล",             "reward": 500, "energy_cost": 15, "hours": 2,
	  "desc": "ขายข้อมูลที่หาได้ให้ผู้สนใจ",
	  "flavor": "ข้อมูลที่มีค่าที่สุดคือข้อมูลที่คนอื่นไม่ควรรู้ว่าแกรู้",
	  "events": [
		{ "desc": "ผู้ซื้อต้องการข้อมูลเพิ่มเติม ต่อรองราคาสูงขึ้น", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
		{ "desc": "ข้อมูลล้าสมัยไปแล้ว ต่อรองราคาลง", "text_color": "red", "money_mod": -100, "energy_mod": 0 },
		{ "desc": "ผู้ซื้อพอใจ แนะนำให้คนอื่นติดต่อมา", "text_color": "white", "money_mod": 80, "energy_mod": 0 },
	  ] },
	## ─── กลุ่มงานฉุกเฉิน ───
	{ "id": 41, "name": "ช่วยเหลือฉุกเฉิน",      "reward": 350, "energy_cost": 20, "hours": 2,
	  "desc": "ช่วยเหลือเหตุการณ์ฉุกเฉินตามที่ได้รับแจ้ง",
	  "flavor": "เหตุฉุกเฉินในย่านนี้มักมีมากกว่าหนึ่งชั้น ชั้นแรกคือสิ่งที่เห็น ชั้นที่สองคือสิ่งที่ไม่ควรเห็น",
	  "events": [
		{ "desc": "สถานการณ์อันตรายกว่าที่บอก แต่ผ่านมาได้ด้วยความสงบ", "text_color": "red", "money_mod": 100, "energy_mod": -12 },
		{ "desc": "ช่วยได้ทันเวลา ผู้รอดชีวิตขอบคุณด้วยสิ่งที่มี", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
	  ] },
	{ "id": 42, "name": "ดับเพลิงรับจ้าง",       "reward": 780, "energy_cost": 42, "hours": 4,
	  "desc": "ช่วยทีมดับเพลิงที่ขาดคน",
	  "flavor": "ไฟเผาทุกอย่างเท่ากัน ทั้งสิ่งที่มีค่าและสิ่งที่ไม่มีค่า",
	  "events": [
		{ "desc": "ไฟลุกลามเร็วกว่าที่คาด ต้องระดมพลังงานสูงสุด", "text_color": "red", "money_mod": 0, "energy_mod": -20 },
		{ "desc": "ช่วยชีวิตคนได้หนึ่งคน ได้รับรางวัลพิเศษ", "text_color": "green", "money_mod": 300, "energy_mod": 0 },
		{ "desc": "ทีมดับเพลิงทำงานเป็นทีมได้ดี งานเสร็จเร็วกว่าที่คาด", "text_color": "green", "money_mod": 0, "energy_mod": 8 },
	  ] },
	{ "id": 43, "name": "พยาบาลฉุกเฉินชั่วคราว", "reward": 460, "energy_cost": 22, "hours": 3,
	  "desc": "ช่วยคลินิกที่ขาดคนในช่วงฉุกเฉิน",
	  "flavor": "คลินิกนี้รักษาคนที่ไม่ต้องการให้ใครรู้ว่าบาดเจ็บ นั่นทำให้ค่าบริการสูงเป็นพิเศษ",
	  "events": [
		{ "desc": "ผู้ป่วยหนักกว่าที่คิด ต้องใช้ทักษะและสมาธิสูง", "text_color": "red", "money_mod": 0, "energy_mod": -10 },
		{ "desc": "ผู้ป่วยที่ช่วยรอดปลอดภัย แพทย์ให้รางวัลพิเศษ", "text_color": "green", "money_mod": 150, "energy_mod": 0 },
	  ] },
	{ "id": 44, "name": "กู้ภัยในพื้นที่พัง",    "reward": 950, "energy_cost": 48, "hours": 6,
	  "desc": "ช่วยกู้ภัยในตึกที่กำลังพัง",
	  "flavor": "ตึกนี้ถูกรื้อถอนโดยไม่ได้แจ้งคนข้างในก่อน มีคนติดอยู่ข้างใน",
	  "events": [
		{ "desc": "พบผู้รอดชีวิตเพิ่ม ต้องใช้แรงพิเศษในการนำออกมา", "text_color": "red", "money_mod": 200, "energy_mod": -20 },
		{ "desc": "โครงสร้างพังบางส่วน แต่ยังปลอดภัยพอ งานเสร็จ", "text_color": "white", "money_mod": 0, "energy_mod": -8 },
	  ] },
	{ "id": 45, "name": "ขับรถฉุกเฉิน",          "reward": 390, "energy_cost": 18, "hours": 3,
	  "desc": "ขับรถส่งผู้ป่วยหรือสินค้าฉุกเฉิน",
	  "flavor": "ไฟสีแดงและไซเรนทำให้ทุกอย่างดูเร่งด่วน แต่สิ่งที่อยู่ในรถทำให้รู้ว่ามันเร่งด่วนจริงๆ",
	  "events": [
		{ "desc": "รถติดหนักมาก ต้องหาเส้นทางใหม่กะทันหัน", "text_color": "red", "money_mod": -40, "energy_mod": -8 },
		{ "desc": "ส่งถึงทันเวลาพอดี ผู้ว่าจ้างโล่งใจมาก โบนัส", "text_color": "green", "money_mod": 120, "energy_mod": 0 },
		{ "desc": "เส้นทางโล่งกว่าที่คิด เสร็จงานเร็ว", "text_color": "green", "money_mod": 0, "energy_mod": 6 },
	  ] },
	## ─── กลุ่มงานกลางคืน ───
	{ "id": 46, "name": "บาร์เทนเดอร์กลางคืน",  "reward": 310, "energy_cost": 22, "hours": 5,
	  "desc": "ทำงานบาร์กลางคืนในย่านต้องห้าม",
	  "flavor": "คนมาที่บาร์นี้ไม่ได้มาดื่ม พวกเขามาหาที่ซ่อนตัวจากบางอย่าง",
	  "events": [
		{ "desc": "ลูกค้าพิเศษทิ้งเงินเยอะผิดปกติบนบาร์ก่อนหายตัวไป", "text_color": "green", "money_mod": 180, "energy_mod": 0 },
		{ "desc": "เกิดทะเลาะวิวาทกลางบาร์ ต้องจัดการ", "text_color": "red", "money_mod": 0, "energy_mod": -10 },
		{ "desc": "คืนสงบ ลูกค้าใจดี ทิปดีมาก", "text_color": "green", "money_mod": 100, "energy_mod": 0 },
	  ] },
	{ "id": 47, "name": "ดีเจงานปาร์ตี้",        "reward": 480, "energy_cost": 20, "hours": 4,
	  "desc": "เปิดเพลงในงานปาร์ตี้ใต้ดิน",
	  "flavor": "คนที่เต้นในที่นี้กำลังลืมบางอย่าง ดนตรีที่เล่นต้องช่วยให้พวกเขาลืมได้",
	  "events": [
		{ "desc": "ฝูงชนชอบเพลงมาก เรียกเล่นต่อเกินเวลา จ่ายค่าโอที", "text_color": "green", "money_mod": 150, "energy_mod": -6 },
		{ "desc": "อุปกรณ์เสียกลางงาน ต้องแก้ปัญหาสด", "text_color": "red", "money_mod": -80, "energy_mod": -8 },
	  ] },
	{ "id": 48, "name": "เฝ้ายามตลาดมืด",        "reward": 560, "energy_cost": 26, "hours": 5,
	  "desc": "เฝ้าพื้นที่ตลาดมืดในช่วงกลางคืน",
	  "flavor": "ตลาดมืดในความหมายตรงตัว ไม่มีไฟ ไม่มีชื่อ มีแค่เสียงและเงา",
	  "events": [
		{ "desc": "มีคนพยายามบุกเข้ามา ขับไล่ออกไปได้โดยไม่บาดเจ็บ โบนัส", "text_color": "green", "money_mod": 150, "energy_mod": -8 },
		{ "desc": "คืนเงียบสงบผิดปกติ มันน่ากังวลกว่าเวลาที่วุ่นวาย", "text_color": "white", "money_mod": 0, "energy_mod": -5 },
	  ] },
	{ "id": 49, "name": "สืบข้อมูลกลางคืน",      "reward": 620, "energy_cost": 25, "hours": 4,
	  "desc": "หาข้อมูลในย่านที่คึกคักกลางคืน",
	  "flavor": "ความจริงที่หายากที่สุดมักซ่อนอยู่ในสถานที่ที่คนส่วนใหญ่กลัวจะเข้า",
	  "events": [
		{ "desc": "พบข้อมูลสำคัญที่ผู้ว่าจ้างต้องการ โบนัสพิเศษ", "text_color": "green", "money_mod": 200, "energy_mod": 0 },
		{ "desc": "มีคนสังเกตเห็นว่ากำลังสืบ ต้องถอยออกมาก่อน", "text_color": "red", "money_mod": -100, "energy_mod": -10 },
		{ "desc": "ข้อมูลที่หามาไม่ตรงกับที่ผู้ว่าจ้างต้องการ แต่ก็ยังจ่ายบางส่วน", "text_color": "white", "money_mod": -50, "energy_mod": -5 },
	  ] },
	{ "id": 50, "name": "คุ้มกันกลุ่มหลบหนี",   "reward": 1200, "energy_cost": 45, "hours": 6,
	  "desc": "นำพาคนกลุ่มหนึ่งออกจากย่านอันตราย",
	  "flavor": "คนที่ต้องหลบหนีกลางดึกมักมีเรื่องราวที่หนักกว่าของเรา ฉันไม่ถาม แค่นำทาง",
	  "events": [
		{ "desc": "เส้นทางถูกปิด ต้องหาเส้นทางใหม่กะทันหัน ใช้พลังงานมากขึ้น", "text_color": "red", "money_mod": 0, "energy_mod": -18 },
		{ "desc": "กลุ่มผ่านไปได้อย่างปลอดภัย ผู้นำกลุ่มให้รางวัลพิเศษ", "text_color": "green", "money_mod": 400, "energy_mod": 0 },
		{ "desc": "หนึ่งในกลุ่มหมดแรงกลางทาง ต้องแบกด้วย", "text_color": "red", "money_mod": 100, "energy_mod": -20 },
	  ] },
]

func _ready() -> void:
	_apply_difficulty()
	_generate_day_jobs()

func _process(delta: float) -> void:
	if not _clock_running:
		return
	_time_accumulator += delta
	var minutes_to_add: int = int(_time_accumulator * MINUTES_PER_REAL_SECOND)
	if minutes_to_add <= 0:
		return
	_time_accumulator -= float(minutes_to_add) / MINUTES_PER_REAL_SECOND
	current_minute += minutes_to_add
	var hour_carry: int = current_minute / 60
	current_minute = current_minute % 60
	if hour_carry > 0:
		current_hour += hour_carry
		if current_hour >= 24:
			current_hour = current_hour % 24
			_midnight_day_advance()
	time_changed.emit()

func _midnight_day_advance() -> void:
	debt_remaining *= (1.0 + debt_interest_rate)
	current_day += 1
	_prev_day_job_ids = _today_job_ids.duplicate()
	_used_job_ids_today.clear()
	jobs_done_today = 0
	daily_money_earned = 0.0; daily_debt_paid = 0.0; daily_energy_used = 0.0
	daily_events.clear()
	_generate_day_jobs()
	day_changed.emit()

func pause_clock() -> void:  _clock_running = false
func resume_clock() -> void: _clock_running = true

func _apply_difficulty() -> void:
	match game_difficulty:
		"easy":
			debt_interest_rate = 0.02; max_days = 9; max_energy = 120.0
			energy = 120.0; total_debt = 3000.0; debt_remaining = 3000.0
		"normal":
			debt_interest_rate = 0.05; max_days = 7; max_energy = 100.0
			energy = 100.0; total_debt = 6000.0; debt_remaining = 6000.0
		"hard":
			debt_interest_rate = 0.09; max_days = 5; max_energy = 80.0
			energy = 80.0; total_debt = 10000.0; debt_remaining = 10000.0

func _generate_day_jobs() -> void:
	var pool: Array[int] = []
	for j in all_jobs:
		pool.append(j["id"])
	for used in _used_job_ids_today:
		pool.erase(used)
	var carryovers: Array[int] = []
	for pid in _prev_day_job_ids:
		if pid in pool and carryovers.size() < 2:
			carryovers.append(pid)
			pool.erase(pid)
	pool.shuffle()
	var new_jobs: Array[int] = []
	new_jobs.append_array(carryovers)
	for i in range(mini(3 - new_jobs.size(), pool.size())):
		new_jobs.append(pool[i])
	_today_job_ids = new_jobs

func refresh_jobs_after_pick(picked_id: int) -> void:
	_used_job_ids_today.append(picked_id)
	_today_job_ids.erase(picked_id)
	var used_all: Array[int] = _used_job_ids_today.duplicate()
	used_all.append_array(_today_job_ids)
	var candidates: Array[int] = []
	for j in all_jobs:
		if not (j["id"] in used_all):
			candidates.append(j["id"])
	candidates.shuffle()
	if candidates.size() > 0:
		_today_job_ids.append(candidates[0])

func get_today_jobs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for jid in _today_job_ids:
		for j in all_jobs:
			if j["id"] == jid:
				result.append(j)
				break
	return result

func advance_time(hours: int) -> void:
	current_hour = (current_hour + hours) % 24
	time_changed.emit()

func get_time_string() -> String:
	var period := "AM" if current_hour < 12 else "PM"
	var h := current_hour % 12
	if h == 0: h = 12
	return "%d:%02d %s" % [h, current_minute, period]

func get_day_string() -> String:
	return "วันที่ %d / %d" % [current_day, max_days]

func get_energy_percent() -> float:
	return clampf((energy / max_energy) * 100.0, 0.0, 100.0)

func get_debt_percent() -> float:
	if total_debt <= 0.0: return 0.0
	return clampf((debt_remaining / total_debt) * 100.0, 0.0, 100.0)

func get_paid_percent() -> float:
	if total_debt <= 0.0: return 100.0
	return clampf((debt_paid / total_debt) * 100.0, 0.0, 100.0)

func do_job(job: Dictionary) -> Dictionary:
	var money_earned: float = float(job["reward"])
	var energy_used: float  = float(job["energy_cost"])
	var event_desc: String  = ""
	var event_color: String = "white"
	var had_event := false

	## สุ่ม event จาก events ของงานนั้น (ถ้ามี) 45% โอกาส
	if randf() < 0.45:
		var job_events: Array = job.get("events", [])
		if job_events.size() > 0:
			var ev: Dictionary = job_events[randi() % job_events.size()]
			money_earned += float(ev.get("money_mod", 0))
			energy_used  -= float(ev.get("energy_mod", 0))
			energy_used   = maxf(energy_used, 0.0)
			event_desc    = ev.get("desc", "")
			event_color   = ev.get("text_color", "white")
			had_event     = true

	money_earned = maxf(money_earned, 0.0)
	money        += money_earned
	energy       -= energy_used
	energy        = maxf(energy, 0.0)
	advance_time(job["hours"])
	jobs_done_today += 1
	daily_money_earned += money_earned
	daily_energy_used  += energy_used
	if had_event:
		daily_events.append(event_desc)
	refresh_jobs_after_pick(job["id"])
	money_changed.emit()

	return {
		"job":              job,
		"money_earned":     money_earned,
		"energy_used":      energy_used,
		"event_desc":       event_desc,
		"event_color":      event_color,
		"had_event":        had_event,
		"energy_remaining": energy,
	}

func pay_debt_partial(amount: float) -> void:
	amount = minf(amount, debt_remaining)
	amount = minf(amount, money)
	if amount <= 0.0: return
	money -= amount; debt_remaining -= amount
	debt_remaining = maxf(debt_remaining, 0.0)
	debt_paid += amount; daily_debt_paid += amount
	energy -= max_energy * 0.05; energy = maxf(energy, 0.0)
	money_changed.emit()

func pay_debt(amount: float) -> void:
	pay_debt_partial(amount)

func buy_food(item_index: int) -> bool:
	if item_index < 0 or item_index >= food_items.size(): return false
	var item: Dictionary = food_items[item_index]
	if money < float(item["cost"]): return false
	money  -= float(item["cost"])
	energy  = minf(energy + item["energy"], max_energy)
	money_changed.emit()
	return true

func save_money() -> void:
	energy = minf(energy + max_energy * 0.05, max_energy)

func rest() -> Dictionary:
	var recovery := randf_range(0.42, 0.52) * max_energy
	energy = minf(energy + recovery, max_energy)
	var summary_lines := build_day_summary_lines()
	debt_remaining *= (1.0 + debt_interest_rate)
	var old_day := current_day
	current_day += 1; current_hour = 8; current_minute = 0; _time_accumulator = 0.0
	_prev_day_job_ids = _today_job_ids.duplicate()
	_used_job_ids_today.clear(); jobs_done_today = 0
	daily_money_earned = 0.0; daily_debt_paid = 0.0; daily_energy_used = 0.0
	daily_events.clear(); _generate_day_jobs(); day_changed.emit()
	return { "day": old_day, "summary_lines": summary_lines, "energy_recovered": recovery }

func build_day_summary_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append({ "text": "วันที่ %d  —  สิ้นสุดกะทำงาน" % current_day, "color": "header" })
	lines.append({ "text": "", "color": "spacer" })
	lines.append({ "text": "งานที่ทำวันนี้:      %d งาน" % jobs_done_today, "color": "normal" })
	lines.append({ "text": "รายได้วันนี้:        $%.0f" % daily_money_earned, "color": "green" })
	if daily_debt_paid > 0.0:
		lines.append({ "text": "จ่ายหนี้วันนี้:      $%.0f" % daily_debt_paid, "color": "green" })
	lines.append({ "text": "พลังงานที่ใช้ไป:     %.0f%%" % daily_energy_used, "color": "yellow" })
	lines.append({ "text": "", "color": "spacer" })
	if daily_events.size() > 0:
		lines.append({ "text": "เหตุการณ์วันนี้:", "color": "dim" })
		for ev in daily_events:
			lines.append({ "text": "  " + ev, "color": "dim" })
		lines.append({ "text": "", "color": "spacer" })
	var next_debt := debt_remaining * (1.0 + debt_interest_rate)
	lines.append({ "text": "หนี้คงเหลือ:         $%.0f" % debt_remaining, "color": "red" })
	lines.append({ "text": "หลังดอกเบี้ย:        $%.0f  (+%.0f%% / วัน)" % [next_debt, debt_interest_rate * 100.0], "color": "red" })
	lines.append({ "text": "พลังงานพรุ่งนี้:     %.0f%%" % energy, "color": "yellow" })
	return lines

func check_condition() -> String:
	if debt_remaining <= 0.0: return "win"
	if energy <= 0.0: return "lose_energy"
	if current_day > max_days: return "lose_time"
	return "continue"

func reset_game() -> void:
	debt_paid = 0.0; money = 0.0; current_day = 1; current_hour = 8; current_minute = 0
	daily_money_earned = 0.0; daily_debt_paid = 0.0; daily_energy_used = 0.0
	daily_events.clear(); jobs_done_today = 0
	_today_job_ids.clear(); _used_job_ids_today.clear(); _prev_day_job_ids.clear()
	_clock_running = true; _time_accumulator = 0.0
	_apply_difficulty(); _generate_day_jobs()
