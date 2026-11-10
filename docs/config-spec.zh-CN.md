# 配置规范（单一规范）

> 英文版：[config-spec.en.md](config-spec.en.md)
>
> 状态：定稿（2026-11-10，T81）。本文件是本项目**唯一**的配置组装规范。
> 任何配置行为与本文件冲突时，以本文件为准并视为缺陷；修改组装层序必须先改本文件。

## 1. 总则

- 任一行为只有一个权威来源、一条组装路径、一套优先序。两处可写同一字段、双存储可分叉、合并顺序靠默契，都算缺陷。
- 生效配置由六层管线自下而上组装，高层覆盖低层；任何字段的最终值必须能追溯到唯一一层。

## 2. 六层管线

| 层 | 名称 | 内容与所有者 |
| --- | --- | --- |
| L0 | 订阅原样 | 当前配置（订阅/本地文件）解析后的原始配置，是组装的底稿。 |
| L1 | 脚本 | 用户脚本对订阅的处理结果（桥接层 scripted config 通道），在 L0 之上、App 补丁之前执行。 |
| L2 | App 设置整段接管 | App 模型（ClashConfig）的 dns / ntp / sniffer / experimental 四段**整段接管**：有 App 段时订阅同名段完全不参与生效；general 标量同理由 App 模型给出。无门控旗。 |
| L3 | 配置级覆盖 | 当前配置专属的覆盖：策略组编辑（group-overrides）、节点排除过滤等，只作用于当前配置。 |
| L4 | 中国适配派生 | 系统显式化选项（拦截类开关）派生运行模式与规则尾：任一拦截项开启时 mode 强制为 rule 并合成 MATCH 尾规则；mode 只许在此层派生，别处不得改写。 |
| L5 | 生成护栏 | 组装末尾的合法性校验与钳制（端口冲突、空值回退、非法项剔除），只做守卫、不引入新语义。 |
| L6 | 桥接归一 | 下发内核前的平台归一化（见 §6 登记表），最后执行、不回写上层，App 侧保存的值不变。 |

组选择（哪个节点被选中）的唯一权威是 App 的 selectedMap；内核侧 `store-selected` 恒为 `false`，内核不得回写选择状态。

## 3. 逐对优先序

| # | 关系 | 说明 |
| --- | --- | --- |
| 1 | L3 组编辑 url > L0 订阅组 url | 仅当编辑器里显式写了 url 才覆盖；清空即恢复订阅值。 |
| 2 | L3 组编辑 url > App 全局测速地址 | 显式编辑优先于全局改写（批 1 C-2）。 |
| 3 | App 全局测速地址 > L0 订阅组 url | 组无显式 url 且开启改写时，prepareSetup 把组 url 改写为 App 测速地址。 |
| 4 | L3 组编辑其余字段 > L0 订阅组同名字段 | 组覆盖整组下发，字段级以编辑值为准。 |
| 5 | L2 四段整段 > L0 订阅同名段 | dns/ntp/sniffer/experimental 整段替换，不做字段级合并（批 3）。 |
| 6 | L2 general 标量 > L0 同名键 | 含 external-ui 地址/名称、geodata-loader、geodata-mode，均以 App 模型为唯一出处（批 3 R-2/R-4）。 |
| 7 | L3 组编辑 exclude-filter 替换 L0 值，再与 App 全局 node-exclude-filter 并集合并 | 编辑值替换订阅值；全局值并集追加的范围与既有全局过滤一致（provider 支撑的组，即 use 非空）（批 2 C-3）。 |
| 8 | L1 脚本 > L0 | 脚本输出覆盖订阅原样，L2 及以上层再在其上组装。 |
| 9 | L4 mode 派生 > 用户所选 mode | 任一拦截项开启时派生值（rule）胜出；setup 与热更新共用同一派生函数（批 1 C-1）。 |
| 10 | selectedMap（App）为组选择唯一权威 | store-selected 恒 false（批 1 R-1a）。 |
| 11 | L5 护栏 > 一切层 | 非法值在护栏被钳制或剔除，任何层不得绕过。 |
| 12 | L6 平台变换最后执行 | 只影响下发内核的副本，不回写 App 模型与订阅。 |
| 13 | 热更新投影 ⊆ setup 参数同源子集 | 热更新（UpdateParams）字段与 setup 同源同值；不在投影内的字段按 §7 标注的时机生效（批 3 P-5）。 |
| 14 | 默认值只在 App 模型定义一处 | 桥接层打底默认只补模型 JSON 未包含的键（模型全量输出时不可达），不得另立默认（批 3 R-5）。 |

## 4. 四段接管与继承式迁移（批 3 定版）

- dns / ntp / sniffer / experimental 四段取消 override 门控旗，一律由 App 模型整段接管。
- 升级一次性迁移（版本标记 `specMigrationVersion`，只跑一次）：旧门控旗为**开**的段，App 模型原本就是权威，原样保留；旧门控旗为**关**的段，模型值从未生效过，升级时先以**当前配置订阅**的该段内容播种 App 模型再接管，保证升级后生效配置逐段与升级前一致；订阅无该段时维持 App 模型现行值（未动过的用户即出厂默认）。
- 判定口径：门控关即视为「该段从未被 App 覆写」——关门控下模型里的任何值都未生效，替换不可能改变生效配置，这是现有持久化能给出的最稳妥口径。
- 迁移结果就是普通 App 模型数据，迁移后用户改动照常；迁移失败不阻塞启动，记日志且仍推进水位。

## 5. 默认值唯一出处（R-5）

- 一切默认值只在 App 模型（`lib/models/clash_config.dart`）定义，UI 与组装层引用模型常量，不得自带字面量。
- 已清除的重复默认：`geodata-loader` 字面量（state.dart）、`geodata-mode` 字面量（state.dart）、external-ui 地址/名称字面量（state.dart）——均改为模型字段携带（geodata-mode 为模型新字段，缺省 `false` 与旧组装字面量一致）。
- 桥接层（core）以 KDF 默认给接管段打底，仅补模型 JSON 未包含的键；App 模型 toJson 全量输出，故打底实际不可达，仅作防御。

## 6. L6 平台归一登记表

| 变换 | 平台 | 说明 |
| --- | --- | --- |
| provider 路径强制重写为 `md5(url)` | 全部 | S-2 定版：订阅 provider 的本地路径不由订阅自带值决定。 |
| DNS listen `:53` → `:10053` | Android | 非特权端口归一；特定条件下 listen 收窄为 `127.0.0.1`。 |
| NTP `write-to-system` 强制 `false` | Android | 平台无系统时间写权限。 |
| tun `auto-route` / `auto-detect-interface` 平台强制值 | 桌面/Android 各自 | 按平台能力强制，不由订阅/App 决定。 |
| Linux 系统 DNS 变更走备份-回读-回滚通道 | Linux | T78 定版：改前备份原状态、改后回读校验、失败自动回滚并在页面两级回报。 |
| route-exclude-address → route-address-set 形态变换 | 按内核要求 | 字段形态归一，不改变语义集合。 |

## 7. 热更新投影与生效时机（P-5）

- 热更新参数（UpdateParams）与 setup 参数同源：mode 走同一派生（批 1）、interface-name 与 setup 同口径下发（批 3 补齐）。
- 不在热更新投影内的字段，改动在下一次 setup（重启核心/重载配置）时生效，App 已在对应设置项标注「重启核心后生效」：UA、keep-alive-interval、keep-alive-idle、bind-address、lan-allowed-ips、lan-disallowed-ips、store-fake-ip、port/socks-port/redir-port/tproxy-port（mixed-port 在投影内，热生效）。
- 部分页面保存时主动触发全量重 setup（如用户认证、GEO 自动更新设置），其字段保存即生效，不属上列。

## 8. 四病收敛状态（T81 审计 19 条）

| 类 | 条数 | 状态 |
| --- | --- | --- |
| 冲突 C | 4 | 全部收敛：C-1 mode 同源、C-2 组 url 显式优先、C-3 exclude-filter 合并语义、C-4 链式下限回显（批 1–2）。 |
| 冗余 R | 5 | 全部收敛：四门控旗删除（R-2 批 3）、store-selected 关闭（R-1a 批 1）、双写字段清除、默认值唯一出处（R-5 批 3）。 |
| 优先级不明 P | 5 | 全部收敛：本文件 §3 逐对定序；P-5 热更新同源与生效时机标注（批 3）。 |
| 影子路径 S | 5 | 全部收敛或登记：geosite 清零拆除（S-1 批 1）、孤儿组提示（S-5 批 2）、provider 路径与平台变换入 §6 登记表（S-2/S-4）。 |

## 9. 验证

- 端到端组装快照：`core/spec_snapshot_test.go`（dns 段接管、组 url 链、exclude-filter 合并）；层序被改动即失败。
- mode 合成链：`test/providers/update_params_mode_test.dart`、`test/common/system_explicit_test.dart`。
- 迁移与接管组装：`test/common/spec_migration_test.dart`、`test/common/setup_params_takeover_test.dart`。
