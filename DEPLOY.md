# MTC Smart Assistant - 部署指南

本指南将帮助你将 MTC Smart Assistant 部署到 Render 平台。

## 后端部署 (Backend Deployment)

后端是一个 ASP.NET Core Web API 项目，支持通过 Docker 部署到 Render。

### 1. 准备工作
- 确保代码已推送到 GitHub。
- 注册并登录 [Render](https://render.com)。
- 准备好 PostgreSQL 数据库（可以使用 Render 的 Managed PostgreSQL 或之前的 Neon DB）。

### 2. 部署步骤
1. 在 Render Dashboard 点击 **New +** -> **Web Service**。
2. 选择 **Build and deploy from a Git repository**。
3. 连接你的 GitHub 仓库 (`mtc-smart-assistant`)。
4. **Name**: `mtc-api` (或你喜欢的名字)。
5. **Region**: 选择离你最近的区域 (e.g. Singapore)。
6. **Branch**: `main`。
7. **Root Directory**: `backend/MtcSales.API` (重要！)。
8. **Runtime**: 选择 **Docker**。
9. **Environment Variables** (环境变量):
   - `DefaultConnection`: 你的 PostgreSQL 连接字符串 (例如: `Host=...;Database=...;Username=...;Password=...`)。
   - `ASPNETCORE_ENVIRONMENT`: `Production`。
10. 点击 **Create Web Service**。

Render 会自动检测目录下的 `Dockerfile` 并开始构建。部署完成后，你将获得一个 URL (例如 `https://mtc-api.onrender.com`)。

---

## 前端部署 (Frontend Deployment)

前端是一个 Flutter 项目，可以构建为 Web 应用或移动应用。

### 选项 A: 部署 Web 版本 (推荐用于测试/管理员)

你可以将 Flutter Web 构建为静态网站，并托管在 Render (Static Site) 或 Vercel/Netlify。这里以 Render 为例：

1. **构建 Web 版本**:
   在本地运行以下命令生成构建产物：
   ```bash
   cd frontend/mtc_sales_app
   flutter build web --release
   ```
   构建产物位于 `build/web` 目录。

2. **部署到 Render (Static Site)**:
   - 在 Render 点击 **New +** -> **Static Site**。
   - 连接 GitHub 仓库。
   - **Root Directory**: `frontend/mtc_sales_app`。
   - **Build Command**: `flutter build web --release` (注意：Render 原生环境可能不支持 Flutter，建议使用 Docker 部署 Web 或手动上传)。
   
   **更简单的方案 (使用 GitHub Pages 或 Vercel)**:
   由于 Render 原生构建 Flutter 较麻烦，推荐使用 **Vercel**。
   1. 在 Vercel 导入仓库。
   2. Root Directory 选择 `frontend/mtc_sales_app`。
   3. Build Command: `flutter build web --release`
   - **注意**: Render 默认环境可能没有 Flutter。
   - **推荐方案**: 使用 Docker 部署 Web 版。
   - 在 `frontend/mtc_sales_app` 下创建一个 `Dockerfile`:
     ```dockerfile
     FROM ghcr.io/cirruslabs/flutter:stable AS build
     WORKDIR /app
     COPY . .
     RUN flutter build web --release

     FROM nginx:alpine
     COPY --from=build /app/build/web /usr/share/nginx/html
     EXPOSE 80
     ```
   - 然后在 Render 上部署一个新的 Web Service，Root Directory 选 `frontend/mtc_sales_app`，Runtime 选 Docker。

### 选项 B: 移动应用 (APK/IPA)

对于员工使用的 App，建议构建安装包。

1. **构建 Android APK**:
   ```bash
   cd frontend/mtc_sales_app
   flutter build apk --release
   ```
   产物路径: `build/app/outputs/flutter-apk/app-release.apk`。
   你可以将此 APK 发送给员工安装。

2. **构建 iOS (需要 Mac + Xcode)**:
   ```bash
   cd frontend/mtc_sales_app
   flutter build ios --release
   ```
   这需要 Apple Developer 账号并通过 TestFlight 分发。

---

## 连接前后端

部署完后端后，记得更新前端的 API 地址：

1. 打开 App (或 Web) 的登录页。
2. 点击右上角 **设置 (Settings)** 图标。
3. 输入 Render 提供的后端 URL (例如 `https://mtc-api.onrender.com/api/`)。
4. 点击保存。

现在你的前端应用将连接到云端后端。
