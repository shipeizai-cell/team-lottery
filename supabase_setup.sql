-- 团建抽奖系统 Supabase 数据库设置脚本
-- 请在Supabase SQL编辑器中执行此脚本

-- 1. 创建参与者表
CREATE TABLE IF NOT EXISTS participants (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL,
  user_name TEXT NOT NULL,
  choice TEXT NOT NULL CHECK (choice IN ('家里蹲', '歆弘府')),
  user_ip TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 添加索引提高查询性能
  CONSTRAINT unique_user_id UNIQUE(user_id)
);

-- 2. 创建索引
CREATE INDEX IF NOT EXISTS idx_participants_user_id ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_choice ON participants(choice);
CREATE INDEX IF NOT EXISTS idx_participants_created_at ON participants(created_at DESC);

-- 3. 启用行级安全策略（RLS）
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;

-- 4. 创建策略：允许插入投票（所有人）
CREATE POLICY "允许所有人插入投票" ON participants
  FOR INSERT WITH CHECK (true);

-- 5. 创建策略：允许所有人读取投票（所有人）
CREATE POLICY "允许所有人读取投票" ON participants
  FOR SELECT USING (true);

-- 6. 创建策略：仅服务角色可删除（管理员）
CREATE POLICY "仅服务角色可删除" ON participants
  FOR DELETE USING (auth.role() = 'service_role');

-- 7. 创建视图：实时统计
CREATE OR REPLACE VIEW vote_statistics AS
SELECT 
  '家里蹲' as option_name,
  COUNT(*) FILTER (WHERE choice = '家里蹲') as vote_count,
  CASE 
    WHEN COUNT(*) > 0 THEN 
      ROUND(COUNT(*) FILTER (WHERE choice = '家里蹲') * 100.0 / COUNT(*), 1)
    ELSE 0 
  END as percentage
FROM participants
UNION ALL
SELECT 
  '歆弘府' as option_name,
  COUNT(*) FILTER (WHERE choice = '歆弘府') as vote_count,
  CASE 
    WHEN COUNT(*) > 0 THEN 
      ROUND(COUNT(*) FILTER (WHERE choice = '歆弘府') * 100.0 / COUNT(*), 1)
    ELSE 0 
  END as percentage
FROM participants;

-- 8. 创建函数：获取领先选项
CREATE OR REPLACE FUNCTION get_leading_choice()
RETURNS TABLE (
  leading_choice TEXT,
  vote_count BIGINT,
  percentage NUMERIC
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  WITH vote_counts AS (
    SELECT 
      choice,
      COUNT(*) as count,
      ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as pct
    FROM participants
    GROUP BY choice
    ORDER BY count DESC
    LIMIT 1
  )
  SELECT 
    COALESCE(choice, '待定') as leading_choice,
    COALESCE(count, 0) as vote_count,
    COALESCE(pct, 0) as percentage
  FROM vote_counts;
END;
$$;

-- 9. 创建函数：检查用户是否已投票
CREATE OR REPLACE FUNCTION check_user_voted(user_id_param TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  has_voted BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM participants WHERE user_id = user_id_param
  ) INTO has_voted;
  
  RETURN has_voted;
END;
$$;

-- 10. 插入测试数据（可选）
INSERT INTO participants (user_id, user_name, choice, user_ip, user_agent) 
VALUES 
  ('test_user_001', '测试用户1', '家里蹲', '127.0.0.1', '测试浏览器'),
  ('test_user_002', '测试用户2', '歆弘府', '127.0.0.1', '测试浏览器'),
  ('test_user_003', '测试用户3', '家里蹲', '127.0.0.1', '测试浏览器')
ON CONFLICT (user_id) DO NOTHING;

-- 11. 验证设置
SELECT '数据库设置完成！' as message;

-- 查看表结构
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'participants'
ORDER BY ordinal_position;

-- 查看测试数据
SELECT * FROM participants ORDER BY created_at DESC LIMIT 5;

-- 查看统计
SELECT * FROM vote_statistics;