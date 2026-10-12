# 美术风格与火系特效 V0.1

日期：2026-10-12。范围：将已经确认的美术样稿接入实际游戏，只制作火系视觉，不增加雷系、水系玩法。

## 这套画风叫什么

推荐简称：**非像素手绘 Q 版奇幻，清晰轮廓，柔和厚涂，亮色元素特效**。

它不是像素风，也不是写实暗黑。角色亲切、比例紧凑；场景用安静的中性灰；攻击的方向和命中阶段是视觉重点。以后复刻时，参考图比堆叠风格词更重要。

### 固定关键词

| 中文 | 英文提示词 | 要保持的感觉 |
| --- | --- | --- |
| 非像素 2D 手绘卡通 | non-pixel 2D hand-painted cartoon | 平滑轮廓，不用像素块 |
| Q 版奇幻、紧凑比例 | chibi fantasy, compact proportions | 大帽兜、短身体、清楚的脚部 |
| 柔和厚涂、块面明暗 | soft painterly shading, broad painted color planes | 大色块和少量明暗层，不靠密集细节 |
| 清晰轮廓、克制描边 | crisp smooth silhouettes, restrained dark outlines | 缩小后仍能看懂，不用粗黑边抢眼 |
| 轻度俯视的三分之四视角 | high top-down three-quarter view | 角色能看到脸和脚；地面是正俯视 |
| 低饱和场景、亮色元素特效 | muted environment, bright stylized elemental VFX | 背景退后，魔法的核心最亮 |
| 撕裂火舌、卷曲尾焰 | ragged flame tongues, curling directional fire tail | 火焰有方向、有破碎轮廓，不是一团橙色雾 |

英文核心串：

```text
non-pixel 2D hand-painted cartoon, chibi fantasy, compact proportions,
soft painterly shading, broad painted color planes, crisp smooth silhouettes,
restrained dark outlines, high top-down three-quarter view,
muted environment, bright stylized elemental VFX
```

### 配色与视角

- 玩家：低饱和青绿衣袍、象牙白布边、少量黄铜扣件。青绿让玩家和橙色火焰彼此分离。
- 场景：中性石灰、石墨灰、少量灰绿苔藓。不要把整张画面染成蓝紫或棕黄。
- 敌人：炭灰、暗酒红、浅色眉眼、小面积余烬红眼睛。
- 火焰：黄白小核心 -> 金橙主体 -> 珊瑚红外焰 -> 少量低透明度余烬。高亮只占局部，避免大面积泛白。
- 角色和道具：约 55 度向下看的三分之四视角，柔和左上光。地板和持续燃烧区域：正俯视。
- 角色原图不带地面阴影，落地阴影由游戏绘制，便于统一位置和暂停行为。

## 下次生成素材的模板

同时附上 `assets/art_samples/v01/player_mage.png` 作为角色画风参考；火系再附上 `fire_vfx_samples.png`。整体布局用 `overall_preview.png` 作参考，但不要把它当作已经落地的动画帧。

```text
Use case: stylized-concept
Asset type: one isolated transparent 2D game sprite for a top-down survivor game.
Input images: Image 1 is a style reference only. Match its painted shading,
palette discipline, compact proportions and restrained dark contour.
Primary request: [describe ONE character, object or effect here].
Style/medium: non-pixel 2D hand-painted cartoon, chibi fantasy,
soft painterly shading, broad painted color planes, crisp smooth silhouette,
restrained dark outline. Readable at 48-72 pixels tall in the actual game.
Composition: full object visible, centered, transparent padding on all sides.
Camera: high top-down three-quarter view, about 55 degrees downward.
Lighting: soft upper-left light. Muted body colors with a few clear accents.
Constraints: real alpha transparency, no floor, no ground shadow, no scene,
no text, no watermark, no border, no sprite sheet, no cinematic perspective.
Avoid: pixel art, photorealism, realistic PBR, anime splash art,
thin sketch lines, heavy black contours, dense tiny details, excessive bloom.
```

火焰特效的主体描述可替换为：

```text
A compact directional stylized fire effect, small yellow-white core,
golden orange midtones, coral-red outer flames, ragged curling flame tongues,
clear flow direction, crisp non-pixel painted shapes, restrained soft glow,
large transparent areas between fragments, no smoke cloud, no orange fog blob.
```

地板或火池要把相机改成 `exact overhead orthographic view`。不要让同一张参考图承担所有工作：角色参考管造型和笔触，火焰参考管颜色和轮廓，整体参考管比例和对比。

这是一套可复用的约束，不保证只输入关键词就得到完全一致的画面。保留参考 PNG，每次只调整主体或一个视觉变量，更容易稳定延续。

## 已落地的基础版本

| 内容 | 当前实现 |
| --- | --- |
| 玩家 | 已确认的青绿法师贴图；呼吸、移动起伏、朝向翻转、施法伸缩、受击闪白和无敌闪烁 |
| 场景 | 已确认的石地材质；镜像拼接、薄边界和轻阴影；支持深色背景 |
| 固定靶与敌人 | 新生成的木靶、炭灰小怪；命中反馈和死亡缩小淡出 |
| 经验物 | 蓝色切面晶体，代码绘制，轻微脉动；原拾取规则不变 |
| 火球 | 发射闪光、方向明确的弹体、短尾迹、命中爆开、余烬；未命中到期只轻微消散 |
| 散射 | 复用同一套火焰贴图；沿原有扇形轨迹发射 |
| 火蛋 | 慢速团状火焰，命中或到期产生持续燃烧区，燃烧跳伤提亮、到期淡出 |
| 试验面板 | 可直接选择火球 / 散射 / 火蛋；规则分页跟随当前武器，火蛋伤害输入对应每跳伤害 |

只改美术和试验入口，没有改现有伤害、射速、弹速、碰撞半径、升级和生存规则。持续燃烧区的外边界固定在真实伤害半径，不随呼吸缩放。

### 火系阶段与 A/B

四格火焰图集依次是：左上发射闪光、右上飞行主体、左下命中爆发、右下余烬。**四格是不同阶段，不是逐帧动画序列。**

| 参数 | A 基线 | B 翻卷 |
| --- | --- | --- |
| 发射闪光 | 0.06 s，无额外火星 | 0.08 s，定向火星 |
| 主体半径 | 10 | 10 |
| 主体扭动 | 0 | 2 |
| 尾迹寿命 | 0.12 s | 0.22 s |
| 命中时长 | 0.18 s | 0.26 s |
| 命中最大半径 | 24 | 28 |
| 余烬寿命 | 0.15 s | 0.35 s |

A/B 使用同一套静态美术，比较的是时序、尾迹和形变。切换后已有攻击保留原版本，新攻击使用新版本。修改视觉参数不参与伤害结算。

特效时钟、角色动画和火池动画由 `Arena._step` 推进，不使用独立的实时动画时钟。暂停会冻住世界画面，0.25 倍慢放也会同时放慢视觉。灰度通过统一着色器覆盖贴图，暂停时仍可切换。火星和火池相位不消耗玩法随机序列。

## 怎么看与怎么练

1. Godot 4.6.1 打开项目，F5，进入“特效试验”。
2. 选火球、散射或火蛋，用空格或“单次触发”发射；也可开启连续自动触发。
3. 用 0.25 倍慢放看发射、飞行、命中和消散，再对比 A/B。每轮只改一个视觉参数。
4. 向下滚动面板可打开灰度、深色背景和碰撞显示，检查视觉大小与实际命中范围的区别。
5. 换武器会清场并还原参数。固定靶适合阶段比较，靶群适合看遮挡，实战适合看密集场面。

建议先练“命中前后能否一眼区分”，再练“尾迹能否说明运动方向”，最后练“同屏多个效果是否仍能看清敌人”。不要把更亮、更大、更久同时当作更好的效果。

## 验收与边界

2026-10-12 验证结果：168 项自动断言通过；实际 GPU 渲染检查通过，包括真实鼠标选择武器、暂停画面像素不变、暂停时灰度覆盖贴图、恢复颜色、连续触发、参数对应、清场、移动与退出复位。

| 实机截图 | 内容 |
| --- | --- |
| [火球飞行](screenshots/fire_v01/01_fireball_flight.png) | 玩家、木靶、石地和火球 |
| [命中](screenshots/fire_v01/02_fireball_hit.png) | 火焰爆开与靶子闪白 |
| [灰度暂停](screenshots/fire_v01/04_grayscale_paused.png) | 实际渲染的灰度检查 |
| [散射](screenshots/fire_v01/06_scatter.png) | 三发扇形火球 |
| [火蛋](screenshots/fire_v01/07_fire_egg.png) | 慢速火焰弹体 |
| [燃烧区](screenshots/fire_v01/08_fire_pool.png) | 落地持续燃烧 |
| [战斗合成场景](screenshots/fire_v01/09_survival_combat.png) | 在真实引擎中布置敌人、经验物与攻击，便于观察整体效果；不是自然随机刷怪截图 |

基础版边界：角色尚无手绘多方向走路/施法帧；火焰靠静态阶段图与程序动画组合；地板的重复规律仍可见。后续可以在保持同样轮廓、配色与视角的前提下，逐步补动画帧和更多变化，不必先更换画风。

## 素材与代码位置

- 初始原图与完整提示词：`assets/art_samples/v01/README.md`。
- 新木靶、敌人、火池原图与完整提示词：`assets/art/fire_v01/README.md`。
- 贴图加载与裁剪：`common/game_art.gd`；灰度/受击着色：`vfx/world_art.gdshader`。
- 弹体、发射和命中：`entities/fireball.gd`、`entities/fire_egg.gd`、`vfx/fx_layer.gd`。
- 持续燃烧：`entities/fire_pool.gd`；原有伤害结算仍在 `systems/fire_egg_manager.gd`。
- 渲染检查：`tests/fire_art_runner.tscn`，输出 `docs/screenshots/fire_v01/`。

PowerShell 验证命令，在项目目录执行：

```powershell
$godot = 'E:\godot\tools\godot461\Godot_v4.6.1-stable_win64_console.exe'
& $godot --headless --path . res://tests/test_runner.tscn
& $godot --path . --fixed-fps 60 --resolution 1280x720 --audio-driver Dummy res://tests/fire_art_runner.tscn
```
