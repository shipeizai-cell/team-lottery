# 🚀 立即执行Supabase SQL脚本指南

## 📋 步骤概览（仅需2分钟）
1. 登录Supabase → 2. 打开SQL编辑器 → 3. 复制完整SQL → 4. 执行

---

## 🔧 详细步骤

### 步骤1：登录Supabase控制台
访问：**https://app.supabase.com**
- 登录你的账户
- 进入项目：**flarbbfcedplhrpswscm**

### 步骤2：进入SQL编辑器
1. 点击左侧菜单中的 **"SQL Editor"**（数据库图标）
2. 点击 **"+ New"** 按钮创建新查询
3. 清空编辑器中的所有内容

### 步骤3：复制并执行完整SQL

**复制以下完整SQL代码**（全选复制）：

```sql
-- 团建饭店抽签系统 - Supabase 数据库初始化脚本
-- 请在Supabase SQL编辑器中执行此完整脚本

-- 1. 创建抽签记录表
CREATE TABLE IF NOT EXISTS lottery_records (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL,
  selected_option TEXT NOT NULL CHECK (selected_option IN ('家里蹲', '歆弘府')),
  user_ip TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建选项计数表（用于快速统计）
CREATE TABLE IF NOT EXISTS option_counts (
  option_name TEXT PRIMARY KEY,
  count INTEGER DEFAULT 0
);

-- 3. 初始化选项计数
INSERT INTO option_counts (option_name, count) 
VALUES 
  ('家里蹲', 0),
  ('歆弘府', 0)
ON CONFLICT (option_name) DO NOTHING;

-- 4. 启用行级安全策略（RLS）
ALTER TABLE lottery_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE option_counts ENABLE ROW LEVEL SECURITY;

-- 5. 创建策略：允许插入抽签记录
CREATE POLICY "允许插入抽签记录" ON lottery_records
  FOR INSERT WITH CHECK (true);

-- 6. 创建策略：允许所有人读取抽签记录
CREATE POLICY "允许读取抽签记录" ON lottery_records
  FOR SELECT USING (true);

-- 7. 创建策略：允许读取选项计数
CREATE POLICY "允许读取选项计数" ON option_counts
  FOR SELECT USING (true);

-- 8. 创建策略：允许更新选项计数（仅通过函数）
CREATE POLICY "允许更新选项计数" ON option_counts
  FOR UPDATE USING (auth.role() = 'service_role');

-- 9. 创建函数：执行抽签并更新计数
CREATE OR REPLACE FUNCTION perform_lottery(
  p_user_id TEXT,
  p_user_ip TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  v_selected_option TEXT;
  v_random_number NUMERIC;
BEGIN
  -- 检查用户是否已抽签
  IF EXISTS (SELECT 1 FROM lottery_records WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION '用户已抽签，不能重复参与';
  END IF;

  -- 生成随机数决定结果（50%概率）
  v_random_number := RANDOM();
  
  IF v_random_number < 0.5 THEN
    v_selected_option := '家里蹲';
  ELSE
    v_selected_option := '歆弘府';
  END IF;

  -- 插入抽签记录
  INSERT INTO lottery_records (user_id, selected_option, user_ip, user_agent)
  VALUES (p_user_id, v_selected_option, p_user_ip, p_user_agent);

  -- 更新选项计数
  UPDATE option_counts 
  SET count = count + 1 
  WHERE option_name = v_selected_option;

  -- 返回抽签结果
  RETURN v_selected_option;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. 创建函数：获取统计数据
CREATE OR REPLACE FUNCTION get_lottery_stats()
RETURNS TABLE (
  option_name TEXT,
  count INTEGER,
  percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    oc.option_name,
    oc.count,
    CASE 
      WHEN (SELECT SUM(count) FROM option_counts) > 0 THEN
        ROUND(oc.count * 100.0 / (SELECT SUM(count) FROM option_counts), 1)
      ELSE 0
    END as percentage
  FROM option_counts oc
  ORDER BY oc.count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. 创建函数：获取用户抽签记录
CREATE OR REPLACE FUNCTION get_user_lottery_result(p_user_id TEXT)
RETURNS TABLE (
  selected_option TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT lr.selected_option, lr.created_at
  FROM lottery_records lr
  WHERE lr.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. 创建视图：实时统计数据
CREATE OR REPLACE VIEW lottery_statistics AS
SELECT 
  '家里蹲' as option_name,
  (SELECT count FROM option_counts WHERE option_name = '家里蹲') as count,
  CASE 
    WHEN (SELECT SUM(count) FROM option_counts) > 0 THEN
      ROUND((SELECT count FROM option_counts WHERE option_name = '家里蹲') * 100.0 / 
            (SELECT SUM(count) FROM option_counts), 1)
    ELSE 0
  END as percentage
UNION ALL
SELECT 
  '歆弘府' as option_name,
  (SELECT count FROM option_counts WHERE option_name = '歆弘府') as count,
  CASE 
    WHEN (SELECT SUM(count) FROM option_counts) > 0 THEN
      ROUND((SELECT count FROM option_counts WHERE option_name = '歆弘府') * 100.0 / 
            (SELECT SUM(count) FROM option_counts), 1)
    ELSE 0
  END as percentage;

-- 13. 测试数据（可选）
INSERT INTO lottery_records (user_id, selected_option, user_ip, user_agent) 
VALUES 
  ('test_user_001', '家里蹲', '127.0.0.1', '测试浏览器'),
  ('test_user_002', '歆弘府', '127.0.0.1', '测试浏览器'),
  ('test_user_003', '家里蹲', '127.0.0.1', '测试浏览器')
ON CONFLICT (user_id) DO NOTHING;

UPDATE option_counts 
SET count = (SELECT COUNT(*) FROM lottery_records WHERE selected_option = '家里蹲')
WHERE option_name = '家里蹲';

UPDATE option_counts 
SET count = (SELECT COUNT(*) FROM lottery_records WHERE selected_option = '歆弘府')
WHERE option_name = '歆弘府';

-- 14. 验证设置
SELECT '✅ 数据库设置完成' as message;

-- 查看表结构
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('lottery_records', 'option_counts')
ORDER BY table_name, ordinal_position;

-- 查看统计数据
SELECT * FROM lottery_statistics;

-- 查看测试记录
SELECT * FROM lottery_records ORDER BY created_at DESC LIMIT 5;
```

### 步骤4：执行SQL
1. **粘贴** 以上完整SQL到编辑器中
2. **点击** "Run" 按钮（通常在右上角）
3. **等待** 执行完成（约5-10秒）

---

## ✅ 执行成功后应该看到

### 第1部分：设置完成消息
```
✅ 数据库设置完成
```

### 第2部分：表结构信息（2个表）
```
table_name      | column_name     | data_type      | is_nullable
lottery_records | id              | bigint         | NO
lottery_records | user_id         | text           | NO
...
option_counts   | option_name     | text           | NO
option_counts   | count           | integer        | YES
```

### 第3部分：统计数据
```
option_name | count | percentage
家里蹲       | 2     | 66.7
歆弘府       | 1     | 33.3
```

### 第4部分：测试记录
```
id | user_id       | selected_option | created_at
1  | test_user_001 | 家里蹲          | 2026-03-25...
2  | test_user_002 | 歆弘府          | 2026-03-25...
3  | test_user_003 | 家里蹲          | 2026-03-25...
```

---

## 🎯 验证完成标志

### 1. Table Editor中应该能看到：
- ✅ `lottery_records` 表
- ✅ `option_counts` 表
- ✅ `lottery_statistics` 视图

### 2. Functions中应该能看到：
- ✅ `perform_lottery` 函数
- ✅ `get_lottery_stats` 函数
- ✅ `get_user_lottery_result` 函数

### 3. Policies中应该能看到：
- ✅ "允许插入抽签记录"
- ✅ "允许读取抽签记录"
- ✅ "允许读取选项计数"
- ✅ "允许更新选项计数"

---

## 🚀 执行完成后立即使用

### 版本A：简化版（立即可用）
链接：**https://shipeizai-cell.github.io/team-lottery/simple-party-lottery.html**
- 特点：本地存储，无需Supabase
- 用途：立即可以发给同事使用

### 版本B：完整版（执行SQL后可用）
链接：**https://shipeizai-cell.github.io/team-lottery/supabase-party-lottery.html**
- 特点：连接Supabase，实时同步
- 用途：完整的抽签体验

---

## 🔧 故障排除

### 问题1：SQL执行失败
- **检查**：SQL编辑器是否清空
- **解决**：全选 → 删除 → 重新粘贴完整SQL

### 问题2：权限错误
- **检查**：是否登录正确的Supabase项目
- **解决**：确认项目ID是 `flarbbfcedplhrpswscm`

### 问题3：表已存在
- **解决**：脚本使用 `IF NOT EXISTS`，可以安全执行多次

### 问题4：函数已存在
- **解决**：脚本使用 `CREATE OR REPLACE`，会自动更新

---

## 🎉 完成！现在可以：
1. ✅ **立即使用简化版**发给同事
2. ✅ **执行SQL后**使用完整版
3. ✅ **开始团建饭店抽签**！

**复制链接发给同事：**
```
https://shipeizai-cell.github.io/team-lottery/simple-party-lottery.html
```

**钉钉分享模板：**
```
🎲 团建饭店随机抽签开始啦！

选项：🏠 家里蹲 vs 🍽️ 歆弘府
规则：50%概率随机抽取，每人仅一次机会

抽签链接：https://shipeizai-cell.github.io/team-lottery/simple-party-lottery.html
实时统计：查看页面中的抽签结果
```