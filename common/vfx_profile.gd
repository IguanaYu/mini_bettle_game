class_name VfxProfile
extends Resource
## 攻击视觉表现参数（开发方案 3.2）。默认值 = 设计文档 6.3 的 A 版基线；
## balance/vfx_fireball_b.tres 为 B 版（翻卷轮廓 + 长尾迹 + 余烬）。

@export var muzzle_flash_time: float = 0.06
@export var muzzle_sparks: bool = false  # B 版 true：发射时向外碎片
@export var body_radius: float = 10.0
@export var body_wobble: float = 0.0  # B 版 > 0：轮廓动态变形强度
@export var trail_lifetime: float = 0.12
@export var hit_flash_time: float = 0.18
@export var hit_max_radius: float = 24.0
@export var ember_lifetime: float = 0.15
@export var brightness: float = 1.0  # 试验面板可调
