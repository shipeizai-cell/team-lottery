# 快速部署说明

## 文件说明
- index.html - 主程序（自动配置向导+投票系统）
- supabase_setup.sql - 数据库SQL脚本
- config.json - 系统配置
- 部署指南.md - 完整部署文档
- Supabase设置教程.md - 数据库配置教程
- 钉钉分享指南.md - 钉钉使用指南
- README.md - 系统说明
- 分享说明.txt - 简单分享说明

## 部署步骤
1. 将整个 deploy 文件夹上传到服务器
2. 访问 index.html 文件
3. 按照向导配置Supabase
4. 获取分享链接发到钉钉

## 本地测试
1. 进入 deploy 目录
2. 使用Python启动本地服务器：
   python3 -m http.server 8080
3. 浏览器访问 http://localhost:8080
