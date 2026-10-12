class_name GameEnums
## 全局枚举（开发方案 3.1）。

enum GameState { MAIN_MENU, SURVIVAL, LEVEL_UP, PAUSED, RESULTS, EXPERIMENT }
enum EnemyState { ALIVE, DYING, RECYCLED }  # DYING 期间无碰撞、不受击、不掉落
enum ElementKind { FIRE, LIGHTNING, WATER }
enum ExperimentPreset { SINGLE_TARGET, TARGET_ARRAY, LIVE_CHASE }
enum VisualVersion { A, B }
enum PlaybackRate { PAUSED, SLOW_025, NORMAL_1 }
enum FireWeapon { FIREBALL, SCATTER, FIRE_EGG }
