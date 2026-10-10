# xixuegui1010

参考《吸血鬼幸存者》的俯视 2D 生存原型，兼作攻击特效试验场。Godot 4.6.1 + GDScript。

- 设计文档：`docs/游戏功能设计文档_V0.1.md`
- 开发方案：`docs/开发方案_V0.1.md`（架构 / 数据结构 / 分阶段计划）

## 运行

用 Godot 4.6.1（`E:\godot\tools\godot461\`）打开本目录，F5 运行。

- **开始生存**：WASD/方向键移动，火球自动攻击最近敌人；击杀掉经验、升级三选一；死亡或活满 5 分钟结算。Esc 暂停，F3 调试页。
- **特效试验**：固定靶场反复观察火球；空格单次触发；面板支持 0.25× 慢放、暂停、A/B 视觉切换、规则/视觉参数分页调整、灰度与碰撞半径显示；Esc 打开试验菜单。

## 测试

```bash
GODOT="E:/godot/tools/godot461/Godot_v4.6.1-stable_win64_console.exe"
"$GODOT" --headless --path . res://tests/test_runner.tscn     # 113 项断言，退出码 0 = 全过
"$GODOT" --path . res://tests/screenshot_runner.tscn          # 真实渲染截两张验收图（会弹窗几秒）
```

测试覆盖设计文档全部 16 条验收用例中可自动验证的部分（A01~A15；A16 的"可辨认性"属人工观察，见 `docs/experiments/FX001.md`）。

## 结构速览

```
balance/    数值配置（.tres）：改平衡不动代码
common/     纯数据结构：AttackRule 与 VfxProfile 严格分离（规则/视觉解耦）
entities/   player / enemy / fireball / exp_gem / ground（Node2D + 自绘）
systems/    spawner / projectile_manager / damage_resolver / xp / upgrade / experiment_controller / sfx
vfx/        fx_layer + 命中/发射/尾迹特效（只读事件，不参与结算）
ui/         代码构建的界面：主菜单 / HUD / 升级 / 暂停 / 结算 / 试验面板
autoload/   EventBus（信号总线）/ Rng（种子可控）/ Game（状态机）
tests/      headless 测试 + 截图脚本
```

## 当前进度

| 里程碑 | 状态 |
| --- | --- |
| Phase 0 工程骨架 | ✅ |
| M0 战斗基础（移动/刷怪/火球扫掠碰撞/伤害管线） | ✅ 63 项测试 |
| M1 生存循环（经验/升级/300s/结算/重开） | ✅ 91 项测试 |
| M2 火球试验（靶场/播放控制/AB/记录模板） | ✅ 113 项测试 + 截图验收 |
| M3 元素扩展（连锁闪电/水波，P1） | ⬜ 未开始（规则类已预留 ChainRule/WaveRule 设计） |

git 提交按阶段划分，`git log --oneline` 可看每阶段测试通过数。
