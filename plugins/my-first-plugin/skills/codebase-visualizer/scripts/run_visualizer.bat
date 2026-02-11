@echo off
cd /d "C:\Users\pb.adcycwgr\Desktop\tool"
python ".claude\skills\codebase-visualizer\scripts\visualize.py" "."
if %errorlevel% neq 0 (
    echo 执行失败，请检查错误信息
    pause
) else (
    echo 可视化成功！已生成 codebase-map.html
    start codebase-map.html
)