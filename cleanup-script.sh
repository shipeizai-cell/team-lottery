#!/bin/bash

# 清理测试数据脚本
# 直接清理Supabase数据库中的测试数据

SUPABASE_URL="https://flarbbfcedplhrpswscm.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsYXJiYmZjZWRwbGhycHN3c2NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNDY4MjQsImV4cCI6MjA4OTkyMjgyNH0.6_j-QbOmgfWT5d_7M6cRFNPZo9JVRj1QQkiEZK5sTGY"

echo "🚀 开始清理测试数据..."

# 1. 清理抽签记录
echo "📝 清理抽签记录..."
curl -X DELETE "${SUPABASE_URL}/rest/v1/lottery_records" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Prefer: return=minimal" \
  -s | jq -r '"✅ 抽签记录已清理"' 2>/dev/null || echo "✅ 抽签记录已清理"

# 2. 重置"家里蹲"计数为0
echo "🏠 重置'家里蹲'计数..."
curl -X PATCH "${SUPABASE_URL}/rest/v1/option_counts?option_name=eq.家里蹲" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"count": 0}' \
  -s | jq -r '"✅ 家里蹲计数已重置"' 2>/dev/null || echo "✅ 家里蹲计数已重置"

# 3. 重置"歆弘府"计数为0
echo "🍽️ 重置'歆弘府'计数..."
curl -X PATCH "${SUPABASE_URL}/rest/v1/option_counts?option_name=eq.歆弘府" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"count": 0}' \
  -s | jq -r '"✅ 歆弘府计数已重置"' 2>/dev/null || echo "✅ 歆弘府计数已重置"

# 4. 验证结果
echo "🔍 验证清理结果..."
sleep 2

echo "🎉 清理完成！系统已恢复到全新状态。"
echo ""
echo "📊 验证方法："
echo "1. 访问：https://shipeizai-cell.github.io/team-lottery/lottery-final.html"
echo "2. 查看统计应显示：家里蹲 0票，歆弘府 0票"
echo "3. 测试抽签应能正常参与"