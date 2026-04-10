# 贪吃蛇游戏 / Snake Game

基于 Claude Code 生成的贪吃蛇游戏合集，包含两个版本。

## 项目结构

```
create_by_minimax/
├── snake.html              # HTML 单文件版本（浏览器直接打开）
├── sprites/                # 资源目录
├── scripts/                # 脚本目录
│   └── main.gd            # Godot 主游戏脚本
├── scenes/                 # 场景目录
│   └── main.tscn           # Godot 主场景
├── sounds/                 # 音效目录
│   ├── eat.wav            # 吃食物音效
│   ├── gameover.wav       # 游戏结束音效
│   └── newrecord.wav       # 新纪录音效
├── project.godot           # Godot 主项目配置
├── icon.svg                # 项目图标
└── claude-code-snake/      # Godot 独立版本（备用）
    └── ...
```

## 版本说明

### HTML 版本 (`snake.html`)

纯 HTML 单文件实现，可直接在浏览器中打开。

**操作方式**：
- 方向键 或 WASD 控制蛇的移动方向
- 空格键 暂停（显示暂停菜单）

**特性**：
- 20×20 网格
- localStorage 最高分记录
- 难度递增（每吃 5 个食物速度加快）
- Web Audio API 音效
- 暂停菜单（继续/重新开始）
- 蛇头/蛇身颜色区分

### Godot 版本 (`scripts/main.gd`)

使用 Godot 4.6 构建的完整游戏项目。

**操作方式**：
- 方向键 控制移动
- ESC 暂停
- Enter 重新开始（游戏结束后）

**特性**：
- 24×24 网格（480×480 可视区域）
- 文件存储最高分记录
- 难度递增（每吃 5 个食物速度加快）
- Python 生成的 WAV 音效
- 暂停菜单（继续/重新开始）
- 蛇头/蛇身颜色区分

## 运行方式

### HTML 版本

直接用浏览器打开 `snake.html` 文件即可。

### Godot 版本

1. 安装 [Godot 4.6+](https://godotengine.org/)
2. 打开 Godot 编辑器
3. 导入项目根目录
4. 点击运行

## 操作指南

| 操作 | HTML 版 | Godot 版 |
|------|---------|----------|
| 上移 | ↑ / W | ↑ |
| 下移 | ↓ / S | ↓ |
| 左移 | ← / A | ← |
| 右移 | → / D | → |
| 暂停 | 空格键 | ESC |
| 重新开始 | Enter / 空格 | Enter |

## 游戏规则

1. 控制蛇吃到红色食物
2. 每吃一个食物得 10 分
3. 蛇身变长一节
4. 撞到墙壁或自己的身体则游戏结束
5. 每累计 50 分，速度加快一次

## 技术栈

- **HTML 版本**: 原生 HTML5 Canvas + JavaScript + Web Audio API
- **Godot 版本**: Godot 4.6 + GDScript + Python 生成 WAV 音效

## 更新日志

### v2.0
- 添加最高分记录功能（localStorage / ConfigFile）
- 添加难度递增系统
- 添加音效反馈（Web Audio API / Python WAV）
- 统一蛇头/蛇身颜色（蛇头亮绿 #4ecca3，蛇身深绿 #3aa882）
- 添加暂停菜单
- 添加代码注释
- 修复 Godot 窗口高度显示问题
