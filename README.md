# Magic Clash

跨平台 Mihomo 核心启动器，基于 Flutter 构建。

## 功能特性

- 一键下载/启动/停止 Mihomo 核心
- 实时流量监控与图表展示
- 代理节点管理与延迟测试
- 连接管理（查看/关闭活动连接）
- 配置文件管理（订阅链接/本地文件导入）
- 支持多种代理协议转换（vmess/trojan/vless/ss）
- 实时日志查看
- 系统代理设置（Windows/Linux）
- 明暗主题切换

## 支持平台

- Windows
- Linux (GNOME/KDE)
- Android (开发中)

## 项目结构

```
lib/
├── main.dart
├── app.dart
├── core/                              # 通用工具类、常量、异常
│   ├── constants.dart                 # API 端口、超时等常量
│   ├── exceptions.dart                # 自定义异常类
│   └── utils/
│       └── byte_formatter.dart        # 字节格式化工具
├── data/
│   ├── models/                        # 数据模型 (PODO)
│   │   ├── config_profile.dart
│   │   ├── connection.dart
│   │   ├── core_version.dart
│   │   ├── log_entry.dart
│   │   ├── proxy.dart
│   │   └── traffic.dart
│   ├── services/
│   │   ├── api/
│   │   │   └── mihomo_api_service.dart  # Mihomo RESTful API 封装
│   │   ├── local_storage/
│   │   │   └── preferences_service.dart # SharedPreferences 封装
│   │   └── native/
│   │       └── platform_interface.dart  # 平台抽象（路径/系统代理）
│   └── repositories/                  # 数据聚合仓库
│       ├── profile_repository.dart    # 配置管理（订阅/文件/编辑）
│       └── core_status_repository.dart # 核心下载与版本管理
├── logic/                             # 状态管理层 (ChangeNotifier)
│   ├── core_runner.dart               # 核心进程管理（启动/停止/日志）
│   ├── home_controller.dart           # 首页状态管理
│   ├── proxy_controller.dart          # 代理节点状态管理
│   └── profile_controller.dart        # 配置文件状态管理
├── presentation/                      # UI 层
│   ├── router.dart                    # GoRouter 路由配置
│   ├── theme/
│   │   └── app_theme.dart             # 主题定义
│   ├── common/
│   │   └── main_shell.dart            # 导航外壳
│   └── features/                      # 按功能划分页面
│       ├── dashboard/
│       │   └── dashboard_screen.dart  # 主页（状态/流量图表）
│       ├── proxy/
│       │   └── proxy_screen.dart      # 代理节点列表
│       ├── connections/
│       │   └── connections_screen.dart # 活动连接管理
│       ├── logs/
│       │   └── logs_screen.dart       # 实时日志
│       ├── profiles/
│       │   ├── profiles_screen.dart   # 配置文件管理
│       │   └── profile_editor_screen.dart # 配置编辑器
│       └── settings/
│           └── settings_screen.dart   # 设置页面
└── utils/
    └── parsers/
        └── subscription_parser.dart   # Base64/节点解析逻辑
```

## 架构说明

项目采用分层架构：

- **Core 层**：通用常量、异常、工具类
- **Data 层**：数据模型、API 服务、本地存储、平台接口、仓库
- **Logic 层**：业务逻辑与状态管理 (ChangeNotifier)
- **Presentation 层**：UI 界面与路由
- **Utils 层**：辅助工具（解析器等）

状态管理使用 `ChangeNotifier` + `ListenableBuilder`。

## 依赖

| 包名 | 用途 |
|------|------|
| go_router | 声明式路由 |
| dio | HTTP 请求 |
| json_annotation | JSON 序列化 |
| path_provider | 平台路径 |
| shared_preferences | 本地存储 |
| fl_chart | 流量图表 |
| window_manager | 桌面窗口管理 |
| archive | 解压核心文件 |
| file_picker | 文件选择 |
| uuid | 唯一 ID 生成 |

## 开发

```bash
# 安装依赖
flutter pub get

# 生成序列化代码
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run -d linux  # 或 windows
```

## 许可证

MIT
