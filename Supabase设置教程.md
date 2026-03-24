# Supabase 详细设置教程

## 第一步：注册和创建项目

### 1.1 访问Supabase
1. 打开 [supabase.com](https://supabase.com)
2. 点击右上角 "Start your project"
3. 使用GitHub账号登录或邮箱注册

### 1.2 创建组织
1. 登录后点击 "New organization"
2. 输入组织名称（如 "公司名-抽奖系统"）
3. 点击 "Create organization"

### 1.3 创建新项目
1. 点击 "New project"
2. 填写项目信息：
   - **Name**: team-lottery-system
   - **Database Password**: 设置一个强密码（保存好！）
   - **Region**: 选择离你最近的地域（新加坡或日本）
   - **Pricing Plan**: 选择 Free Plan

3. 点击 "Create new project"
4. 等待项目初始化（约1-2分钟）

## 第二步：获取API凭证

### 2.1 进入项目设置
项目创建完成后，点击左侧菜单：
1. **Settings** → **API**

### 2.2 记录关键信息
复制以下信息到安全的地方：

```
Project URL: https://xxxxxxxxxxxx.supabase.co
API Key (anon public): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Project ID: xxxxxxxxxxxxxx
```

## 第三步：创建数据库表

### 3.1 进入SQL编辑器
左侧菜单点击 **SQL Editor** → **New query**

### 3.2 执行建表SQL
复制以下SQL代码到编辑器中：

```sql
-- 创建参与者表
CREATE TABLE IF NOT EXISTS participants (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL,
  user_name TEXT NOT NULL,
  choice TEXT NOT NULL CHECK (choice IN ('家里蹲', '歆弘府')),
  user_ip TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引提高查询性能
CREATE INDEX IF NOT EXISTS idx_participants_user_id ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_choice ON participants(choice);
CREATE INDEX IF NOT EXISTS idx_participants_created_at ON participants(created_at DESC);

-- 启用行级安全策略（RLS）
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;

-- 创建插入策略：允许所有人插入
CREATE POLICY "允许所有人插入投票" ON participants
  FOR INSERT WITH CHECK (true);

-- 创建读取策略：允许所有人读取
CREATE POLICY "允许所有人读取投票" ON participants
  FOR SELECT USING (true);

-- 可选：创建删除策略（仅管理员）
CREATE POLICY "仅管理员可删除" ON participants
  FOR DELETE USING (auth.role() = 'service_role');
```

### 3.3 执行SQL
点击 **Run** 按钮执行SQL语句。

## 第四步：测试数据库连接

### 4.1 进入Table Editor
左侧菜单点击 **Table Editor** → **participants**

### 4.2 手动插入测试数据
点击 **Insert row**，填写：
- user_id: `test_user_001`
- user_name: `测试用户`
- choice: `家里蹲`
- user_ip: `127.0.0.1`
- user_agent: `测试浏览器`

点击 **Save** 保存。

### 4.3 验证数据
应该能看到刚刚插入的数据，说明数据库配置成功。

## 第五步：修改前端代码

### 5.1 下载修改版HTML
我为你准备了完整的Supabase版本，请使用这个文件：

```html
<!-- 完整代码见附件：lottery-supabase.html -->
```

### 5.2 替换API凭证
在HTML文件中找到以下部分，替换为你的Supabase信息：

```javascript
// 替换这两行
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 5.3 添加Supabase客户端库
确保HTML中包含Supabase JS库：
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

## 第六步：部署前端

### 6.1 本地测试
1. 用浏览器打开修改后的HTML文件
2. 按F12打开开发者工具
3. 查看Console标签，应该看到连接成功的消息

### 6.2 上传到服务器
选择一种部署方式：

#### 方式A：GitHub Pages（免费）
1. 创建GitHub仓库
2. 上传HTML文件
3. 启用GitHub Pages
4. 访问 `https://用户名.github.io/仓库名/lottery.html`

#### 方式B：公司服务器
1. 上传到公司Web服务器
2. 获取访问URL
3. 测试访问

#### 方式C：云存储（推荐）
1. 腾讯云COS / 阿里云OSS
2. 上传HTML文件
3. 设置为静态网站托管
4. 获取CDN加速URL

## 第七步：钉钉集成

### 7.1 生成分享链接
部署后获取可访问的URL，如：
- `https://your-domain.com/lottery.html`
- `https://your-bucket.cos.ap-beijing.myqcloud.com/lottery.html`

### 7.2 钉钉消息模板
在钉钉群中发送：

```
【团建饭店投票开始】🏢

各位同事，团建饭店投票已经开始！

投票选项：
🏠 家里蹲 - 温馨舒适，自由自在
🍽️ 歆弘府 - 豪华餐厅，美食盛宴

投票规则：
✅ 每人只能投票一次
✅ 实时统计，公平公正
✅ 最终以票数最多的选项为准

立即投票：https://your-url.com/lottery.html

截止时间：今日 20:00
```

### 7.3 钉钉机器人（可选）
如果需要更高级的集成：
1. 创建钉钉自定义机器人
2. 配置Webhook
3. 发送投票卡片消息

## 第八步：管理员功能

### 8.1 查看实时统计
系统自动显示：
- 总投票人数
- 各选项得票数
- 实时百分比
- 参与者列表

### 8.2 数据导出
在Supabase中：
1. 进入 **Table Editor** → **participants**
2. 点击 **Export** 导出CSV
3. 可用于Excel分析

### 8.3 重置投票（如需）
```sql
-- 清空所有投票数据（谨慎使用）
TRUNCATE TABLE participants RESTART IDENTITY;
```

## 故障排除

### 问题1：无法连接Supabase
✅ 检查：
- API URL和Key是否正确
- 网络是否可以访问Supabase
- 浏览器控制台错误信息

### 问题2：无法插入数据
✅ 检查：
- 表名是否正确（participants）
- RLS策略是否配置
- 字段名称是否匹配

### 问题3：统计不更新
✅ 检查：
- 前端轮询是否正常工作
- Supabase查询是否有错误
- 浏览器缓存问题（尝试硬刷新）

### 问题4：重复投票
✅ 检查：
- user_id是否唯一
- 前端是否正确检查已投票状态
- 数据库UNIQUE约束是否生效

## 性能优化建议

### 1. 启用数据库缓存
```sql
-- 为常用查询创建物化视图
CREATE MATERIALIZED VIEW vote_stats AS
SELECT 
  choice,
  COUNT(*) as vote_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM participants
GROUP BY choice;
```

### 2. 前端优化
- 使用CDN加速静态资源
- 启用浏览器缓存
- 压缩HTML/CSS/JS

### 3. 监控设置
- 设置Supabase监控告警
- 记录投票峰值时间
- 定期备份数据

## 安全注意事项

### 1. API密钥保护
- 不要将service_role密钥暴露在前端
- 定期轮换API密钥
- 使用环境变量存储敏感信息

### 2. 防刷票机制
```sql
-- 添加IP限制（可选）
CREATE OR REPLACE FUNCTION check_ip_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    SELECT COUNT(*) 
    FROM participants 
    WHERE user_ip = NEW.user_ip 
    AND created_at > NOW() - INTERVAL '1 hour'
  ) > 3 THEN
    RAISE EXCEPTION '同一IP投票次数过多';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ip_limit_trigger
BEFORE INSERT ON participants
FOR EACH ROW EXECUTE FUNCTION check_ip_limit();
```

### 3. 数据隐私
- 不要收集不必要的个人信息
- 明确告知用户数据使用方式
- 定期清理旧数据

## 支持与维护

### 定期检查
1. 每月检查Supabase使用量
2. 备份数据库
3. 更新依赖库

### 扩展功能
如需扩展功能，可以考虑：
1. 添加微信小程序版本
2. 集成公司OA系统
3. 添加抽奖动画效果
4. 支持多轮投票

---

## 快速检查清单

- [ ] Supabase项目创建完成
- [ ] 数据库表创建成功
- [ ] API凭证已获取并配置
- [ ] 前端页面测试通过
- [ ] 部署到可访问的服务器
- [ ] 钉钉分享链接生成
- [ ] 进行小范围测试
- [ ] 正式发布到团队群

**完成以上步骤后，你的多人抽奖系统就可以正式使用了！**

如有问题，可查阅：
- [Supabase官方文档](https://supabase.com/docs)
- [GitHub Issues](https://github.com/supabase/supabase/issues)
- 或联系技术支持