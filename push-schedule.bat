@echo off
chcp 65001 >nul
echo.
echo ================================
echo  予約投稿をGitHubに送信します
echo ================================
echo.

cd /d "%~dp0"

git add x-scheduled-posts.json
git diff --staged --quiet
if %errorlevel% == 0 (
    echo スケジュールに変更はありませんでした。
    pause
    exit /b 0
)

git commit -m "chore: 予約投稿スケジュール更新"
git push

echo.
echo ✅ GitHubに送信完了！
echo    30分以内にGitHub Actionsが自動的に投稿します。
echo.
pause
