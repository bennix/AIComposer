#!/usr/bin/env python3
"""Generate Compositor/Localizable.xcstrings for en, zh-Hans, zh-Hant, ja, ko."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ui_strings_extra import register as register_extra

# English key -> {zh-Hans, zh-Hant, ja, ko}
T = {}

def add(en, hans, hant, ja, ko):
    T[en] = {"zh-Hans": hans, "zh-Hant": hant, "ja": ja, "ko": ko}

# Language / settings
add("Compositor", "Compositor", "Compositor", "Compositor", "Compositor")
add("Point Sample", "点取样", "點取樣", "ポイントサンプル", "포인트 샘플")
add("3 by 3 Average", "3×3 平均", "3×3 平均", "3×3平均", "3×3 평균")
add("5 by 5 Average", "5×5 平均", "5×5 平均", "5×5平均", "5×5 평균")
add("System Default", "跟随系统", "跟隨系統", "システム設定に従う", "시스템 기본값")
add("Language", "语言", "語言", "言語", "언어")
add("General", "通用", "一般", "一般", "일반")
add("Appearance follows the selected language for every control, menu, tooltip, and AI prompt.",
    "所选语言会应用到每一个控件、菜单、提示和 AI 提示词。",
    "所選語言會套用到每一個控制項、選單、提示和 AI 提示詞。",
    "選択した言語は、すべてのコントロール、メニュー、ツールチップ、AIプロンプトに適用されます。",
    "선택한 언어가 모든 컨트롤, 메뉴, 툴팁, AI 프롬프트에 적용됩니다.")

# Common
add("OK", "好", "好", "OK", "확인")
add("Cancel", "取消", "取消", "キャンセル", "취소")
add("Save", "保存", "儲存", "保存", "저장")
add("Undo", "撤销", "復原", "取り消す", "실행 취소")
add("Redo", "重做", "重做", "やり直す", "다시 실행")
add("Undo %@", "撤销%@", "復原%@", "%@を取り消す", "%@ 실행 취소")
add("Redo %@", "重做%@", "重做%@", "%@をやり直す", "%@ 다시 실행")
add("Cut", "剪切", "剪下", "カット", "잘라내기")
add("Copy", "拷贝", "拷貝", "コピー", "복사")
add("Paste", "粘贴", "貼上", "ペースト", "붙여넣기")
add("Copy Merged", "拷贝合并", "拷貝合併", "結合してコピー", "병합하여 복사")
add("Delete", "删除", "刪除", "削除", "삭제")
add("Preview", "预览", "預覽", "プレビュー", "미리보기")
add("Reset", "重置", "重設", "リセット", "재설정")
add("Width", "宽度", "寬度", "幅", "너비")
add("Height", "高度", "高度", "高さ", "높이")
add("Size", "尺寸", "尺寸", "サイズ", "크기")
add("Model", "模型", "模型", "モデル", "모델")
add("Prompt", "提示词", "提示詞", "プロンプト", "프롬프트")
add("Extra instruction", "补充说明", "補充說明", "追加指示", "추가 지시")
add("Presets", "预设", "預設", "プリセット", "프리셋")
add("Generate", "生成", "產生", "生成", "생성")
add("Apply", "应用", "套用", "適用", "적용")
add("Working…", "处理中…", "處理中…", "処理中…", "작업 중…")
add("px", "像素", "像素", "px", "px")
add("Untitled", "未命名", "未命名", "名称未設定", "제목 없음")
add("Fit", "适合", "符合", "フィット", "맞추기")
add("100%", "100%", "100%", "100%", "100%")

# File menu
add("New Canvas…", "新建画布…", "新增畫布…", "新規キャンバス…", "새 캔버스…")
add("Open Project…", "打开项目…", "開啟專案…", "プロジェクトを開く…", "프로젝트 열기…")
add("Import Images…", "导入图像…", "匯入影像…", "画像を読み込む…", "이미지 가져오기…")
add("Generate Image…", "生成图像…", "產生影像…", "画像を生成…", "이미지 생성…")
add("Save As…", "另存为…", "另存新檔…", "別名で保存…", "다른 이름으로 저장…")
add("Export PNG…", "导出 PNG…", "匯出 PNG…", "PNGを書き出す…", "PNG보내기…")
add("Export JPEG…", "导出 JPEG…", "匯出 JPEG…", "JPEGを書き出す…", "JPEG보내기…")
add("Close Project", "关闭项目", "關閉專案", "プロジェクトを閉じる", "프로젝트 닫기")
add("Check for Updates…", "检查更新…", "檢查更新…", "アップデートを確認…", "업데이트 확인…")

# View
add("Fit Canvas", "适合画布", "符合畫布", "キャンバスに合わせる", "캔버스에 맞추기")
add("Actual Pixels", "实际像素", "實際像素", "実際のピクセル", "실제 픽셀")
add("Zoom In", "放大", "放大", "拡大", "확대")
add("Zoom Out", "缩小", "縮小", "縮小", "축소")
add("Pixel Grid (800% and above)", "像素网格（800% 及以上）", "像素網格（800% 以上）", "ピクセルグリッド（800%以上）", "픽셀 격자(800% 이상)")
add("Show Transform Controls", "显示变换控件", "顯示變形控制項", "変形コントロールを表示", "변형 컨트롤 표시")
add("Hide Compositor", "隐藏 Compositor", "隱藏 Compositor", "Compositorを隠す", "Compositor 가리기")
add("Hide Others", "隐藏其他", "隱藏其他", "ほかを隠す", "기타 가리기")
add("Show All", "全部显示", "全部顯示", "すべてを表示", "모두 보기")

# Edit extras
add("Fill with Foreground Color", "前景色填充", "前景色填滿", "描画色で塗りつぶす", "전경색으로 채우기")
add("Fill with Background Color", "背景色填充", "背景色填滿", "背景色で塗りつぶす", "배경색으로 채우기")
add("Clear Selection Pixels", "清除选区像素", "清除選取像素", "選択範囲のピクセルを消去", "선택 픽셀 지우기")
add("Content-Aware Fill…", "内容识别填充…", "內容感知填滿…", "コンテンツに応じた塗りつぶし…", "내용 인식 채우기…")

# Select
add("Select", "选择", "選擇", "選択", "선택")
add("All", "全部", "全部", "すべて", "모두")
add("Deselect", "取消选择", "取消選取", "選択解除", "선택 해제")
add("Inverse", "反选", "反選", "選択範囲を反転", "반전")
add("Layer's Pixels", "图层像素", "圖層像素", "レイヤーのピクセル", "레이어 픽셀")
add("Mask's Black Areas", "蒙版黑色区域", "遮罩黑色區域", "マスクの黒領域", "마스크 검정 영역")
add("Expand by %@ px", "扩展 %@ 像素", "擴展 %@ 像素", "%@ px拡張", "%@ px 확장")
add("Contract by %@ px", "收缩 %@ 像素", "收縮 %@ 像素", "%@ px縮小", "%@ px 축소")

# Image
add("Image", "图像", "影像", "イメージ", "이미지")
add("Curves…", "曲线…", "曲線…", "カーブ…", "곡선…")
add("Levels…", "色阶…", "色階…", "レベル…", "레벨…")
add("Hue/Saturation…", "色相/饱和度…", "色相/飽和度…", "色相/彩度…", "색조/채도…")
add("Invert", "反相", "反相", "階調の反転", "반전")
add("Invert Mask", "反相蒙版", "反相遮罩", "マスクを反転", "마스크 반전")
add("Canvas Size…", "画布大小…", "畫布大小…", "キャンバスサイズ…", "캔버스 크기…")
add("Image Size…", "图像大小…", "影像大小…", "画像サイズ…", "이미지 크기…")
add("Flip Canvas Horizontal", "水平翻转画布", "水平翻轉畫布", "キャンバスを水平方向に反転", "캔버스 가로 뒤집기")
add("Flip Canvas Vertical", "垂直翻转画布", "垂直翻轉畫布", "キャンバスを垂直方向に反転", "캔버스 세로 뒤집기")

# Filter / Layer / AI menus
add("Filter", "滤镜", "濾鏡", "フィルター", "필터")
add("Layer", "图层", "圖層", "レイヤー", "레이어")
add("AI", "AI", "AI", "AI", "AI")
add("New Adjustment Layer", "新建调整图层", "新增調整圖層", "新規調整レイヤー", "새 조정 레이어")
add("Edit Adjustment…", "编辑调整…", "編輯調整…", "調整を編集…", "조정 편집…")
add("Transform Selection", "变换选区", "變形選取範圍", "選択範囲を変形", "선택 영역 변형")
add("Transform Layer", "变换图层", "變形圖層", "レイヤーを変形", "레이어 변형")
add("Duplicate Layer", "复制图层", "複製圖層", "レイヤーを複製", "레이어 복제")
add("Layer via Copy", "通过拷贝的图层", "透過拷貝的圖層", "コピーしたレイヤー", "복사한 레이어")
add("Create Clipping Mask", "创建剪贴蒙版", "建立剪裁遮罩", "クリッピングマスクを作成", "클리핑 마스크 만들기")
add("Release Clipping Mask", "释放剪贴蒙版", "釋放剪裁遮罩", "クリッピングマスクを解除", "클리핑 마스크 해제")
add("Group Selected Layers", "编组所选图层", "群組所選圖層", "選択したレイヤーをグループ化", "선택한 레이어 그룹화")
add("Move Out of Folder", "移出文件夹", "移出檔案夾", "フォルダから出す", "폴더에서 빼기")
add("New Blank Layer", "新建空白图层", "新增空白圖層", "新規空白レイヤー", "새 빈 레이어")
add("Rename Layer…", "重命名图层…", "重新命名圖層…", "レイヤー名を変更…", "레이어 이름 변경…")
add("Show Layer", "显示图层", "顯示圖層", "レイヤーを表示", "레이어 보기")
add("Hide Layer", "隐藏图层", "隱藏圖層", "レイヤーを隠す", "레이어 숨기기")
add("Move Layer Up", "上移图层", "上移圖層", "レイヤーを上へ", "레이어 위로")
add("Move Layer Down", "下移图层", "下移圖層", "レイヤーを下へ", "레이어 아래로")
add("Flip Layer Horizontal", "水平翻转图层", "水平翻轉圖層", "レイヤーを水平方向に反転", "레이어 가로 뒤집기")
add("Flip Layer Vertical", "垂直翻转图层", "垂直翻轉圖層", "レイヤーを垂直方向に反転", "레이어 세로 뒤집기")
add("Delete Layer", "删除图层", "刪除圖層", "レイヤーを削除", "레이어 삭제")
add("Delete Layers", "删除图层", "刪除圖層", "レイヤーを削除", "레이어 삭제")
add("Delete Layer Mask", "删除图层蒙版", "刪除圖層遮罩", "レイヤーマスクを削除", "레이어 마스크 삭제")
add("AI Settings…", "AI 设置…", "AI 設定…", "AI設定…", "AI 설정…")

# Tools
add("Eyedropper", "吸管", "滴管", "スポイト", "스포이드")
add("Eyedropper (I)", "吸管 (I)", "滴管 (I)", "スポイト (I)", "스포이드 (I)")
add("Marquee (M)", "选框 (M)", "選框 (M)", "選択範囲 (M)", "선택 윤곽 (M)")
add("Lasso (L)", "套索 (L)", "套索 (L)", "なげなわ (L)", "올가미 (L)")
add("Magic Wand (W)", "魔棒 (W)", "魔術棒 (W)", "自動選択 (W)", "마법봉 (W)")
add("Brush (B) · Eraser (E)", "画笔 (B) · 橡皮擦 (E)", "筆刷 (B) · 橡皮擦 (E)", "ブラシ (B) · 消しゴム (E)", "브러시 (B) · 지우개 (E)")
add("Spot Healing Brush (J)", "污点修复画笔 (J)", "污點修復筆刷 (J)", "スポット修復ブラシ (J)", "스팟 복구 브러시 (J)")
add("Clone Stamp (S) · Option-click sets the source", "仿制图章 (S) · Option-单击设源", "仿製圖章 (S) · Option-點一下設來源", "スタンプ (S) · Optionクリックでソース指定", "복제 도장 (S) · Option-클릭으로 소스 지정")
add("Smear (R)", "涂抹 (R)", "塗抹 (R)", "指先 (R)", "문지르기 (R)")
add("Gradient (G)", "渐变 (G)", "漸層 (G)", "グラデーション (G)", "그라디언트 (G)")
add("Shape (U) · Shift-U switches Rectangle/Ellipse", "形状 (U) · Shift-U 切换矩形/椭圆", "形狀 (U) · Shift-U 切換矩形/橢圓", "シェイプ (U) · Shift-Uで矩形/楕円", "도형 (U) · Shift-U로 사각형/타원")
add("Crop (C)", "裁剪 (C)", "裁切 (C)", "切り抜き (C)", "자르기 (C)")
add("Move / Transform (V)", "移动 / 变换 (V)", "移動 / 變形 (V)", "移動 / 変形 (V)", "이동 / 변형 (V)")
add("Hand (H)", "抓手 (H)", "抓手 (H)", "手のひら (H)", "손 도구 (H)")
add("Zoom (Z)", "缩放 (Z)", "縮放 (Z)", "ズーム (Z)", "확대/축소 (Z)")
add("Select a tool", "选择工具", "選擇工具", "ツールを選択", "도구 선택")
add("Sample Ring", "取样环", "取樣環", "サンプルリング", "샘플 링")
add("New canvas", "新建画布", "新增畫布", "新規キャンバス", "새 캔버스")
add("New canvas (⌘N)", "新建画布 (⌘N)", "新增畫布 (⌘N)", "新規キャンバス (⌘N)", "새 캔버스 (⌘N)")
add("Fit canvas in window (⌘0)", "适合窗口 (⌘0)", "符合視窗 (⌘0)", "ウィンドウに合わせる (⌘0)", "창에 맞추기 (⌘0)")
add("Actual pixels (⌘1)", "实际像素 (⌘1)", "實際像素 (⌘1)", "実際のピクセル (⌘1)", "실제 픽셀 (⌘1)")
add("Zoom in (⌘+)", "放大 (⌘+)", "放大 (⌘+)", "拡大 (⌘+)", "확대 (⌘+)")
add("Zoom out (⌘−)", "缩小 (⌘−)", "縮小 (⌘−)", "縮小 (⌘−)", "축소 (⌘−)")

# Welcome / canvas
add("A blank space for your next composition.", "为下一次合成准备的空白画布。", "為下一次合成準備的空白畫布。", "次の合成のための真っさらなキャンバス。", "다음 합성을 위한 빈 캔버스입니다.")
add("Transparent canvas · sRGB", "透明画布 · sRGB", "透明畫布 · sRGB", "透明キャンバス · sRGB", "투명 캔버스 · sRGB")
add("Enter whole numbers from 1 to 30,000 pixels.", "请输入 1 到 30,000 的整数像素。", "請輸入 1 到 30,000 的整數像素。", "1〜30,000ピクセルの整数を入力してください。", "1에서 30,000 사이의 정수 픽셀을 입력하세요.")
add("Open project", "打开项目", "開啟專案", "プロジェクトを開く", "프로젝트 열기")
add("Import image", "导入图像", "匯入影像", "画像を読み込む", "이미지 가져오기")
add("Generate image", "生成图像", "產生影像", "画像を生成", "이미지 생성")
add("Create canvas", "创建画布", "建立畫布", "キャンバスを作成", "캔버스 만들기")
add("Ready when you are", "准备就绪", "準備就緒", "準備完了", "준비 완료")
add("sRGB · Transparent", "sRGB · 透明", "sRGB · 透明", "sRGB · 透明", "sRGB · 투명")
add("Importing images…", "正在导入图像…", "正在匯入影像…", "画像を読み込み中…", "이미지 가져오는 중…")
add("Generating with AI…", "正在使用 AI 生成…", "正在使用 AI 產生…", "AIで生成中…", "AI로 생성 중…")
add("Import couldn’t finish", "导入未能完成", "匯入未能完成", "読み込みを完了できませんでした", "가져오기를 완료할 수 없음")
add("Couldn’t paint", "无法绘制", "無法繪製", "ペイントできませんでした", "칠할 수 없음")
add("Couldn’t crop", "无法裁剪", "無法裁切", "切り抜きできませんでした", "자를 수 없음")

# Layers panel
add("Create a canvas or import an image.", "请先创建画布或导入图像。", "請先建立畫布或匯入影像。", "キャンバスを作成するか画像を読み込んでください。", "캔버스를 만들거나 이미지를 가져오세요.")
add("Import an image or add a blank layer.", "导入图像或添加空白图层。", "匯入影像或新增空白圖層。", "画像を読み込むか空白レイヤーを追加してください。", "이미지를 가져오거나 빈 레이어를 추가하세요.")
add("New blank layer (⇧⌘N)", "新建空白图层 (⇧⌘N)", "新增空白圖層 (⇧⌘N)", "新規空白レイヤー (⇧⌘N)", "새 빈 레이어 (⇧⌘N)")
add("New blank layer", "新建空白图层", "新增空白圖層", "新規空白レイヤー", "새 빈 레이어")
add("Group selected layers (⌘G)", "编组所选图层 (⌘G)", "群組所選圖層 (⌘G)", "選択したレイヤーをグループ化 (⌘G)", "선택한 레이어 그룹화 (⌘G)")
add("New folder", "新建文件夹", "新增檔案夾", "新規フォルダ", "새 폴더")
add("New adjustment layer", "新建调整图层", "新增調整圖層", "新規調整レイヤー", "새 조정 레이어")
add("Delete layer mask", "删除图层蒙版", "刪除圖層遮罩", "レイヤーマスクを削除", "레이어 마스크 삭제")
add("Delete selected layers", "删除所选图层", "刪除所選圖層", "選択したレイヤーを削除", "선택한 레이어 삭제")
add("Delete selected layer", "删除所选图层", "刪除所選圖層", "選択したレイヤーを削除", "선택한 레이어 삭제")
add("Enable/Disable Mask", "启用/停用蒙版", "啟用/停用遮罩", "マスクを有効/無効", "마스크 사용/사용 안 함")
add("Delete Mask", "删除蒙版", "刪除遮罩", "マスクを削除", "마스크 삭제")
add("Delete Layer / Folder", "删除图层 / 文件夹", "刪除圖層 / 檔案夾", "レイヤー / フォルダを削除", "레이어 / 폴더 삭제")

# Filters / adjustments raw values
add("Gaussian Blur", "高斯模糊", "高斯模糊", "ぼかし（ガウス）", "가우시안 흐림")
add("Motion Blur", "动感模糊", "動態模糊", "ぼかし（移動）", "동작 흐림")
add("Add Noise", "添加杂色", "加入雜訊", "ノイズを加える", "노이즈 추가")
add("Lens Correction", "镜头校正", "鏡頭校正", "レンズ補正", "렌즈 교정")
add("Remove Background", "移去背景", "移除背景", "背景を削除", "배경 제거")
add("Content-Aware Fill", "内容识别填充", "內容感知填滿", "コンテンツに応じた塗りつぶし", "내용 인식 채우기")
add("Curves", "曲线", "曲線", "カーブ", "곡선")
add("Levels", "色阶", "色階", "レベル", "레벨")
add("Hue/Saturation", "色相/饱和度", "色相/飽和度", "色相/彩度", "색조/채도")
add("Exposure", "曝光度", "曝光", "露光量", "노출")
add("Gradient Map", "渐变映射", "漸層對應", "グラデーションマップ", "그라디언트 맵")
add("Grain", "颗粒", "顆粒", "粒状", "그레인")
add("Basic", "基本", "基本", "基本", "기본")
add("Advanced", "高级", "進階", "詳細", "고급")
add("Quality", "品质", "品質", "品質", "품질")
add("Radius", "半径", "半徑", "半径", "반경")
add("Angle", "角度", "角度", "角度", "각도")
add("Distance", "距离", "距離", "距離", "거리")
add("Amount", "数量", "數量", "量", "양")
add("Opacity", "不透明度", "不透明度", "不透明度", "불투명도")
add("Refine", "细化", "細化", "調整", "다듬기")
add("Contrast", "对比度", "對比", "コントラスト", "대비")
add("Shift Edge", "移动边缘", "移動邊緣", "エッジをシフト", "가장자리 이동")
add("Remove Distortion", "减少扭曲", "減少扭曲", "ゆがみを補正", "왜곡 제거")
add("Uniform", "平均分布", "平均分布", "均一", "균일")
add("Gaussian", "高斯分布", "高斯分布", "ガウス", "가우시안")
add("Monochromatic", "单色", "單色", "モノクロ", "단색")
add("Limited to the selection", "仅限选区", "僅限選取範圍", "選択範囲に限定", "선택 영역으로 제한")
add("New", "新建", "新增", "新規", "새로 만들기")
add("Add", "添加", "加入", "追加", "추가")
add("Subtract", "减去", "減去", "削除", "빼기")
add("Paint", "绘画", "繪製", "ペイント", "칠하기")
add("Erase", "擦除", "擦除", "消去", "지우기")
add("Liquify", "液化", "液化", "液化", "액화")
add("Blur", "模糊", "模糊", "ぼかし", "흐림")
add("Smudge", "涂抹", "塗抹", "指先", "문지르기")
add("Content-Aware", "内容识别", "內容感知", "コンテンツに応じる", "내용 인식")
add("Create Texture", "创建纹理", "建立紋理", "テクスチャを作成", "텍스처 만들기")
add("Proximity Match", "邻近匹配", "鄰近符合", "近傍一致", "근접 일치")
add("Foreground to Background", "前景到背景", "前景到背景", "描画色から背景色", "전경에서 배경")
add("Foreground to Transparent", "前景到透明", "前景到透明", "描画色から透明", "전경에서 투명")
add("Linear", "线性", "線性", "線形", "선형")
add("Radial", "径向", "徑向", "円形", "원형")
add("Nearest", "最近邻", "最近鄰", "ニアレスト", "최근접")
add("Smooth", "平滑", "平滑", "スムーズ", "부드럽게")
add("High quality", "高质量", "高品質", "高品質", "고품질")
add("Master", "全图", "全圖", "マスター", "전체")
add("Reds", "红色", "紅色", "レッド", "빨강")
add("Yellows", "黄色", "黃色", "イエロー", "노랑")
add("Greens", "绿色", "綠色", "グリーン", "초록")
add("Cyans", "青色", "青色", "シアン", "청록")
add("Blues", "蓝色", "藍色", "ブルー", "파랑")
add("Magentas", "品红", "洋紅", "マゼンタ", "자홍")
add("RGB", "RGB", "RGB", "RGB", "RGB")
add("Red", "红", "紅", "レッド", "빨강")
add("Green", "绿", "綠", "グリーン", "초록")
add("Blue", "蓝", "藍", "ブルー", "파랑")
add("Blend mode", "混合模式", "混合模式", "描画モード", "혼합 모드")

# Blend
add("Normal", "正常", "正常", "通常", "보통")
add("Multiply", "正片叠底", "色彩增值", "乗算", "곱하기")
add("Screen", "滤色", "濾色", "スクリーン", "스크린")
add("Overlay", "叠加", "覆蓋", "オーバーレイ", "오버레이")
add("Darken", "变暗", "變暗", "比較（暗）", "어둡게")
add("Lighten", "变亮", "變亮", "比較（明）", "밝게")
add("Difference", "差值", "差異", "差の絶対値", "차이")
add("Color Dodge", "颜色减淡", "顏色減淡", "覆い焼きカラー", "색상 닷지")
add("Color Burn", "颜色加深", "顏色加深", "焼き込みカラー", "색상 번")
add("Hue", "色相", "色相", "色相", "색조")
add("Saturation", "饱和度", "飽和度", "彩度", "채도")
add("Color", "颜色", "顏色", "カラー", "색상")
add("Luminosity", "明度", "明度", "輝度", "광도")

# AI settings
add("Provider", "服务商", "服務商", "プロバイダ", "제공자")
add("Base URL", "接口地址", "介面位址", "ベースURL", "기본 URL")
add("API Key", "API 密钥", "API 金鑰", "APIキー", "API 키")
add("ZenMux OpenAI-compatible endpoint. Gemini Flash Lite Image is sent through the matching Vertex path.",
    "ZenMux 的 OpenAI 兼容接口。Gemini Flash Lite Image 会走对应的 Vertex 路径。",
    "ZenMux 的 OpenAI 相容介面。Gemini Flash Lite Image 會走對應的 Vertex 路徑。",
    "ZenMuxのOpenAI互換エンドポイント。Gemini Flash Lite Imageは対応するVertex経路で呼び出します。",
    "ZenMux의 OpenAI 호환 엔드포인트입니다. Gemini Flash Lite Image는 해당 Vertex 경로로 호출됩니다.")
add("Hide API key", "隐藏密钥", "隱藏金鑰", "APIキーを隠す", "API 키 숨기기")
add("Show API key", "显示密钥", "顯示金鑰", "APIキーを表示", "API 키 보기")
add("Stored as AES-GCM encrypted JSON in this Mac’s Application Support folder. The unwrap key stays in the Keychain.",
    "以 AES-GCM 加密 JSON 保存在本机 Application Support 目录，解包密钥存放在钥匙串。",
    "以 AES-GCM 加密 JSON 儲存在本機 Application Support 目錄，解包金鑰存放在鑰匙圈。",
    "このMacのApplication SupportにAES-GCM暗号化JSONとして保存し、復号キーはキーチェーンに置きます。",
    "이 Mac의 Application Support에 AES-GCM 암호화 JSON으로 저장하며, 해제 키는 키체인에 둡니다.")
add("Test API Key", "测试 API 密钥", "測試 API 金鑰", "APIキーをテスト", "API 키 테스트")
add("Testing…", "测试中…", "測試中…", "テスト中…", "테스트 중…")
add("No API key yet", "还没有 API 密钥", "還沒有 API 金鑰", "APIキーがまだありません", "아직 API 키가 없습니다")
add("If you do not have a ZenMux API key, open an invite link, register, then create a key and paste it above.",
    "如果还没有 ZenMux API 密钥，请打开邀请链接注册，然后创建密钥并粘贴到上方。",
    "如果還沒有 ZenMux API 金鑰，請開啟邀請連結註冊，然後建立金鑰並貼到上方。",
    "ZenMuxのAPIキーがない場合は、招待リンクで登録し、キーを作成して上に貼り付けてください。",
    "ZenMux API 키가 없다면 초대 링크로 가입한 뒤 키를 만들어 위에 붙여 넣으세요.")
add("Invite link or code", "邀请链接或邀请码", "邀請連結或邀請碼", "招待リンクまたはコード", "초대 링크 또는 코드")
add("Open Invite Link", "打开邀请链接", "開啟邀請連結", "招待リンクを開く", "초대 링크 열기")
add("Open Key Console", "打开密钥控制台", "開啟金鑰主控台", "キーコンソールを開く", "키 콘솔 열기")
add("Accepts `https://zenmux.ai/invite/…` or a bare invite code. After signup, create the key at zenmux.ai/settings/keys.",
    "可填写 `https://zenmux.ai/invite/…` 或邀请码。注册后到 zenmux.ai/settings/keys 创建密钥。",
    "可填寫 `https://zenmux.ai/invite/…` 或邀請碼。註冊後到 zenmux.ai/settings/keys 建立金鑰。",
    "`https://zenmux.ai/invite/…` または招待コードを入力できます。登録後、zenmux.ai/settings/keys でキーを作成します。",
    "`https://zenmux.ai/invite/…` 또는 초대 코드를 입력하세요. 가입 후 zenmux.ai/settings/keys에서 키를 만듭니다.")
add("Default model", "默认模型", "預設模型", "デフォルトモデル", "기본 모델")
add("Verification", "验证", "驗證", "検証", "검증")
add("Key testing is available now. Per-model live checks can be added here later without changing how the key is stored.",
    "现在可以测试密钥。以后可在此添加分模型验证，无需改动密钥存储方式。",
    "現在可以測試金鑰。以後可在此新增分模型驗證，無需改動金鑰儲存方式。",
    "キーのテストは利用できます。モデル別の検証は、保存方法を変えずに後から追加できます。",
    "지금 키를 테스트할 수 있습니다. 모델별 검증은 저장 방식을 바꾸지 않고 나중에 추가할 수 있습니다.")
add("API key saved to this Mac.", "API 密钥已保存到这台 Mac。", "API 金鑰已儲存到這台 Mac。", "APIキーをこのMacに保存しました。", "API 키를 이 Mac에 저장했습니다.")
add("Invite link saved. After ZenMux creates your key, paste it here.",
    "邀请链接已保存。在 ZenMux 创建密钥后粘贴到这里。",
    "邀請連結已儲存。在 ZenMux 建立金鑰後貼到這裡。",
    "招待リンクを保存しました。ZenMuxでキーを作成したらここに貼り付けてください。",
    "초대 링크를 저장했습니다. ZenMux에서 키를 만든 뒤 여기에 붙여 넣으세요.")
add("Paste a ZenMux invite link or invite code first.",
    "请先粘贴 ZenMux 邀请链接或邀请码。",
    "請先貼上 ZenMux 邀請連結或邀請碼。",
    "先にZenMuxの招待リンクまたはコードを貼り付けてください。",
    "먼저 ZenMux 초대 링크 또는 코드를 붙여 넣으세요.")
add("Opened the invite page. After you register, create an API key and paste it here.",
    "已打开邀请页。注册后创建 API 密钥并粘贴到这里。",
    "已開啟邀請頁。註冊後建立 API 金鑰並貼到這裡。",
    "招待ページを開きました。登録後にAPIキーを作成してここに貼り付けてください。",
    "초대 페이지를 열었습니다. 가입 후 API 키를 만들어 여기에 붙여 넣으세요.")
add("Opened the ZenMux key console.", "已打开 ZenMux 密钥控制台。", "已開啟 ZenMux 金鑰主控台。", "ZenMuxのキーコンソールを開きました。", "ZenMux 키 콘솔을 열었습니다.")
add("No API key yet. Use a ZenMux invite link to register, then paste the key in Settings.",
    "还没有 API 密钥。请用 ZenMux 邀请链接注册，然后到设置里粘贴密钥。",
    "還沒有 API 金鑰。請用 ZenMux 邀請連結註冊，然後到設定裡貼上金鑰。",
    "APIキーがありません。ZenMuxの招待リンクで登録し、設定にキーを貼り付けてください。",
    "아직 API 키가 없습니다. ZenMux 초대 링크로 가입한 뒤 설정에 키를 붙여 넣으세요.")
add("Add and save an API key in Settings first.",
    "请先在设置中添加并保存 API 密钥。",
    "請先在設定中新增並儲存 API 金鑰。",
    "先に設定でAPIキーを追加して保存してください。",
    "먼저 설정에서 API 키를 추가하고 저장하세요.")

# AI groups / models
add("Transform", "变换", "變形", "変形", "변형")
add("Edit", "编辑", "編輯", "編集", "편집")
add("Canvas", "画布", "畫布", "キャンバス", "캔버스")
add("GPT Image 2.5 Sunburst", "GPT Image 2.5 Sunburst", "GPT Image 2.5 Sunburst", "GPT Image 2.5 Sunburst", "GPT Image 2.5 Sunburst")
add("Qwen Image 3.0 Pro", "通义万相 3.0 Pro", "通義萬相 3.0 Pro", "Qwen Image 3.0 Pro", "Qwen Image 3.0 Pro")
add("Gemini 3.1 Flash Lite Image", "Gemini 3.1 Flash Lite Image", "Gemini 3.1 Flash Lite Image", "Gemini 3.1 Flash Lite Image", "Gemini 3.1 Flash Lite Image")
add("OpenAI · detailed edits", "OpenAI · 精细编辑", "OpenAI · 精細編輯", "OpenAI · 精密な編集", "OpenAI · 정밀 편집")
add("Qwen · text and layout", "通义 · 文字与排版", "通義 · 文字與排版", "Qwen · 文字とレイアウト", "Qwen · 텍스트와 레이아웃")
add("Google Vertex · fast drafts", "Google Vertex · 快速草稿", "Google Vertex · 快速草稿", "Google Vertex · 高速ドラフト", "Google Vertex · 빠른 초안")

# AI commands
add("Generate Image", "生成图像", "產生影像", "画像を生成", "이미지 생성")
add("Variation", "变体", "變體", "バリエーション", "변형")
add("Pattern / Texture", "图案 / 纹理", "圖案 / 紋理", "パターン / テクスチャ", "패턴 / 텍스처")
add("Poster / Type", "海报 / 字体", "海報 / 字體", "ポスター / 文字", "포스터 / 타이포")
add("Restyle", "风格转绘", "風格轉繪", "スタイル変換", "스타일 변환")
add("Sketch to Image", "线稿成图", "線稿成圖", "スケッチから画像", "스케치를 이미지로")
add("Colorize", "上色", "上色", "カラー化", "채색")
add("Relight", "重打光", "重打光", "ライティング変更", "재조명")
add("Enhance / Upscale", "增强 / 超分", "增強 / 超解析", "高解像度化", "향상 / 업스케일")
add("Cleanup", "清理", "清理", "クリーンアップ", "정리")
add("Restore Photo", "修复照片", "修復照片", "写真を修復", "사진 복원")
add("Fill Selection", "选区补全", "選取補全", "選択範囲を埋める", "선택 영역 채우기")
add("Remove Object", "去除物体", "去除物件", "オブジェクトを除去", "객체 제거")
add("Remove Handwriting", "去除手写", "去除手寫", "手書きを除去", "손글씨 제거")
add("Remove Text", "去除文字", "去除文字", "文字を除去", "텍스트 제거")
add("Replace Background", "替换背景", "取代背景", "背景を置き換え", "배경 교체")
add("Replace Sky", "替换天空", "取代天空", "空を置き換え", "하늘 교체")
add("Weather / Time", "天气 / 时段", "天氣 / 時段", "天候 / 時間帯", "날씨 / 시간대")
add("Recolor", "改色", "改色", "再着色", "재채색")
add("Change Material", "更换材质", "更換材質", "材質を変更", "재질 변경")
add("Harmonize", "统一光色", "統一光色", "調和", "조화")
add("Contact Shadow", "接触阴影", "接觸陰影", "接地シャドウ", "접촉 그림자")
add("Generative Expand", "生成式扩图", "生成式擴圖", "生成拡張", "생성형 확장")
add("Left", "左", "左", "左", "왼쪽")
add("Right", "右", "右", "右", "오른쪽")
add("Top", "上", "上", "上", "위")
add("Bottom", "下", "下", "下", "아래")

# AI presets
add("Oil painting", "油画", "油畫", "油絵", "유화")
add("Watercolor", "水彩", "水彩", "水彩", "수채화")
add("Editorial photo", "杂志摄影", "雜誌攝影", "エディトリアル写真", "화보 사진")
add("Anime still", "动漫静帧", "動漫靜幀", "アニメ静止画", "애니메 스틸")
add("Risograph poster", "孔版海报", "孔版海報", "リソグラフポスター", "리소그래프 포스터")
add("Soft window light", "柔和窗光", "柔和窗光", "柔らかい窓明かり", "부드러운 창빛")
add("Dramatic rim light", "戏剧轮廓光", "戲劇輪廓光", "ドラマチックなリムライト", "드라마틱한 림라이트")
add("Studio three-point", "影棚三点光", "影棚三點光", "スタジオ三点照明", "스튜디오 3점 조명")
add("Golden hour", "黄金时段", "黃金時段", "ゴールデンアワー", "골든아워")
add("Overcast", "阴天", "陰天", "曇り", "흐림")
add("Blue hour", "蓝调时刻", "藍調時刻", "ブルーアワー", "블루아워")
add("Rain at night", "雨夜", "雨夜", "夜の雨", "밤비")
add("Snow", "雪", "雪", "雪", "눈")
add("Fog", "雾", "霧", "霧", "안개")
add("Photoreal product", "照片级产品", "照片級產品", "フォトリアルな製品", "실사 제품")
add("Matte illustration", "哑光插画", "霧面插畫", "マットイラスト", "매트 일러스트")
add("Architectural viz", "建筑效果图", "建築效果圖", "建築ビジュアライゼーション", "건축 시각화")
add("Seamless white studio", "无缝白棚", "無縫白棚", "シームレス白ホリゾ", "심리스 화이트 스튜디오")
add("Soft gray cyclorama", "浅灰天幕", "淺灰天幕", "ソフトグレーホリゾ", "소프트 그레이 사이클로라마")
add("Cedar forest", "雪松森林", "雪松森林", "杉の森", "삼나무 숲")
add("Marble lobby", "大理石大堂", "大理石大廳", "大理石のロビー", "대리석 로비")
add("Clear dusk", "晴朗黄昏", "晴朗黃昏", "晴れの夕暮れ", "맑은 황혼")
add("Storm", "暴风雨", "暴風雨", "嵐", "폭풍")
add("Sunset streaks", "晚霞条纹云", "晚霞條紋雲", "夕焼けの筋雲", "노을 줄무늬 구름")
add("Night with stars", "星空夜晚", "星空夜晚", "星空の夜", "별이 있는 밤")

# AI errors / help (titles already above; help + prompts)
add("Open or create a canvas first.", "请先打开或创建画布。", "請先開啟或建立畫布。", "先にキャンバスを開くか作成してください。", "먼저 캔버스를 열거나 만드세요.")
add("Draw a selection first, then run this command.", "请先绘制选区，再运行此命令。", "請先繪製選取範圍，再執行此命令。", "先に選択範囲を作成してから実行してください。", "먼저 선택 영역을 그린 뒤 이 명령을 실행하세요.")
add("Draw a selection or select one or more objects first, then run this command.",
    "请先绘制选区，或选中一个或多个对象，再运行此命令。",
    "請先繪製選取範圍，或選取一個或多個物件，再執行此命令。",
    "先に選択範囲を作るか、オブジェクトを選んでから実行してください。",
    "먼저 선택 영역을 그리거나 하나 이상의 오브젝트를 선택한 뒤 이 명령을 실행하세요.")
add("Enter a prompt describing what you want.", "请输入描述目标的提示词。", "請輸入描述目標的提示詞。", "作りたい内容をプロンプトで入力してください。", "원하는 내용을 프롬프트로 입력하세요.")
add("The model returned no image. Try another model or a shorter prompt.",
    "模型没有返回图像。请换一个模型或缩短提示词。",
    "模型沒有返回影像。請換一個模型或縮短提示詞。",
    "モデルが画像を返しませんでした。別のモデルか短いプロンプトを試してください。",
    "모델이 이미지를 반환하지 않았습니다. 다른 모델이나 더 짧은 프롬프트를 시도하세요.")
add("The image service returned HTTP %d.", "图像服务返回 HTTP %d。", "影像服務返回 HTTP %d。", "画像サービスがHTTP %dを返しました。", "이미지 서비스가 HTTP %d를 반환했습니다.")
add("Enter at least one side to expand.", "请至少填写一边的扩展像素。", "請至少填寫一邊的擴展像素。", "拡張する辺を少なくとも1つ入力してください。", "확장할 변을 하나 이상 입력하세요.")
add("Add an API key in Settings before generating or editing images.",
    "生成或编辑图像前，请先在设置中添加 API 密钥。",
    "產生或編輯影像前，請先在設定中新增 API 金鑰。",
    "画像の生成や編集の前に、設定でAPIキーを追加してください。",
    "이미지를 생성하거나 편집하기 전에 설정에서 API 키를 추가하세요.")

# AI default prompts (sent to models)
add("ai.prompt.variation",
    "重新演绎这张图：保持主体与构图，但充分改变细节、气质和氛围，让它明显是新的一张。不要加字幕。",
    "重新演繹這張圖：保持主體與構圖，但充分改變細節、氣質和氛圍，讓它明顯是新的一張。不要加字幕。",
    "この画像の新しいバリエーションを作ってください。被写体と構図は保ち、細部・スタイル・雰囲気は明らかに新しいものにしてください。キャプションは入れないでください。",
    "이 이미지를 새롭게 변주하세요. 피사체와 구도는 유지하되 세부, 스타일, 분위기는 분명히 다르게 만드세요. 캡션은 넣지 마세요.")
add("ai.prompt.restyle",
    "按要求的风格重绘此图。保留构图、主体身份和可读文字。风格作用于媒介、光影和质感。",
    "按要求的風格重繪此圖。保留構圖、主體身份和可讀文字。風格作用於媒介、光影和質感。",
    "指定のスタイルで描き直してください。構図、被写体の同一性、読みやすい文字は維持し、媒体・照明・仕上げにスタイルを適用してください。",
    "요청한 스타일로 다시 그리세요. 구도, 주체 정체성, 읽히는 글자는 유지하고 매체·조명·마감에 스타일을 적용하세요.")
add("ai.prompt.sketch",
    "把这张线稿或草图画成完成的照片级或精致插画。尊重线条和比例，合理发明材质与光影。",
    "把這張線稿或草圖畫成完成的照片級或精緻插畫。尊重線條和比例，合理發明材質與光影。",
    "このスケッチを完成した写真または洗練されたイラストにしてください。線と比率を尊重し、妥当な材質と照明を与えてください。",
    "이 스케치를 완성된 실사 또는 세련된 일러스트로 만드세요. 선과 비율을 존중하고 타당한 재질과 조명을 부여하세요.")
add("ai.prompt.colorize",
    "为这张图上色，颜色自然、符合时代。保持边缘清晰，不要发明新物体，已有颜色予以保留。",
    "為這張圖上色，顏色自然、符合時代。保持邊緣清晰，不要發明新物體，已有顏色予以保留。",
    "この画像を自然で時代に即した色でカラー化してください。輪郭はシャープに、新しい物体は加えず、既存の色は残してください。",
    "이 이미지에 자연스럽고 시대에 맞는 색을 입히세요. 가장자리는 선명하게, 새 물체는 만들지 말고 기존 색은 유지하세요.")
add("ai.prompt.relight",
    "按要求重新打光。几何、身份和文字不变。阴影、高光和反射光必须匹配新光线。",
    "按要求重新打光。幾何、身份和文字不變。陰影、高光和反射光必須匹配新光線。",
    "指定どおり再照明してください。形状、同一性、文字は変えず、影・ハイライト・反射光を新しい光に合わせてください。",
    "요청대로 다시 조명하세요. 형태, 정체성, 글자는 유지하고 그림자·하이라이트·반사광을 새 빛에 맞추세요.")
add("ai.prompt.enhance",
    "增强此图：提高清晰度与纹理、恢复文字细节、减少伪影，保持原有观感。不要改构图或添加物体。",
    "增強此圖：提高清晰度與紋理、恢復文字細節、減少偽影，保持原有觀感。不要改構圖或添加物體。",
    "解像感と質感を上げ、文字を回復し、アーティファクトを減らしてください。見た目の系統は変えず、構図や物体は追加しないでください。",
    "선명도와 질감을 높이고 글자를 회복하며 아티팩트를 줄이세요. 원래 느낌을 유지하고 구도를 바꾸거나 물체를 추가하지 마세요.")
add("ai.prompt.cleanup",
    "清理此图：去掉灰尘、斑点、压缩块和轻微模糊。不要美化人脸，不要重构图，保留真实颗粒。",
    "清理此圖：去掉灰塵、斑點、壓縮塊和輕微模糊。不要美化人臉，不要重構圖，保留真實顆粒。",
    "埃、斑点、圧縮ノイズ、軽いボケを除去してください。顔の美化や再構図はせず、本物の粒子は残してください。",
    "먼지, 반점, 압축 노이즈, 약한 흐림을 제거하세요. 얼굴을 보정하거나 재구성하지 말고 진짜 그레인은 남기세요.")
add("ai.prompt.restore",
    "修复这张受损照片：处理划痕、撕裂、污渍和褪色。保留人物身份与年代气质，不要现代化服饰或背景。",
    "修復這張受損照片：處理刮痕、撕裂、污漬和褪色。保留人物身份與年代氣質，不要現代化服飾或背景。",
    "傷んだ写真を修復し、傷・破れ・汚れ・退色を直してください。人物と時代性は保ち、服装や背景を現代的にしないでください。",
    "손상된 사진을 복원해 긁힘, 찢어짐, 얼룩, 바램을 고치세요. 인물과 시대 분위기는 유지하고 옷이나 배경을 현대화하지 마세요.")
add("ai.prompt.fill",
    "补全透明/蒙版区域，使其与周围图像一致。保持光线、透视、纹理和风格。不要改不透明区域。",
    "補全透明/遮罩區域，使其與周圍影像一致。保持光線、透視、紋理和風格。不要改不透明區域。",
    "透明/マスク領域を周囲と一致するように埋めてください。照明・遠近感・質感・スタイルを保ち、不透明部は変更しないでください。",
    "투명/마스크 영역을 주변과 맞게 채우세요. 조명, 원근, 질감, 스타일을 유지하고 불투명 영역은 바꾸지 마세요.")
add("ai.prompt.removeObject",
    "去掉透明/蒙版区域中的物体，并重建匹配的自然背景。不要留下物体或其阴影的痕迹。",
    "去掉透明/遮罩區域中的物體，並重建匹配的自然背景。不要留下物體或其陰影的痕跡。",
    "透明/マスク領域の物体を除去し、周囲に合う自然な背景を再構築してください。物体や影の痕跡を残さないでください。",
    "투명/마스크 영역의 물체를 제거하고 주변에 맞는 자연 배경을 재구성하세요. 물체나 그림자 흔적을 남기지 마세요.")
add("ai.prompt.handwriting",
    "去掉手写笔迹、签名、墨迹和涂鸦。精确保留印刷文字、字体、印章和印刷图形。保留纸张纹理。",
    "去掉手寫筆跡、簽名、墨跡和塗鴉。精確保留印刷文字、字體、印章和印刷圖形。保留紙張紋理。",
    "手書き、署名、インク、落書きを除去し、印刷文字・活字・印影・印刷グラフィックは正確に残してください。紙の質感も残してください。",
    "손글씨, 서명, 잉크, 낙서를 제거하고 인쇄 문자, 활자, 도장, 인쇄 그래픽은 정확히 남기세요. 종이 질감도 유지하세요.")
add("ai.prompt.removeText",
    "去掉叠加的文字、标题、文字水印和标签，并重建背景。场景中原有的标志与图形予以保留。",
    "去掉疊加的文字、標題、文字浮水印和標籤，並重建背景。場景中原有的標誌與圖形予以保留。",
    "重ねられた文字、キャプション、文字ウォーターマーク、ラベルを除去して背景を再構築してください。元からあるロゴや図は残してください。",
    "겹친 글자, 캡션, 문자 워터마크, 라벨을 제거하고 배경을 재구성하세요. 원래 장면의 로고와 그래픽은 남기세요.")
add("ai.prompt.replaceBackground",
    "替换主体背后的背景。保留主体、头发和接触边缘。让主体受光匹配新环境。不要增加人物。",
    "取代主體背後的背景。保留主體、頭髮和接觸邊緣。讓主體受光匹配新環境。不要增加人物。",
    "被写体の背後の背景だけを置き換え、髪と接地際は残してください。新しい環境の光に被写体を合わせ、人物は追加しないでください。",
    "피사체 뒤 배경만 바꾸고 피사체, 머리카락, 접촉 가장자리는 유지하세요. 새 환경의 빛에 맞추고 사람을 추가하지 마세요.")
add("ai.prompt.replaceSky",
    "只替换天空。保留地平线、建筑和植被。让地面受光匹配新天空。不要移动机位。",
    "只取代天空。保留地平線、建築和植被。讓地面受光匹配新天空。不要移動機位。",
    "空だけを置き換え、地平線・建物・植生は残してください。地面の光を新しい空に合わせ、カメラ位置は動かさないでください。",
    "하늘만 바꾸고 수평선, 건물, 식생은 유지하세요. 땅의 빛을 새 하늘에 맞추고 카메라 위치는 옮기지 마세요.")
add("ai.prompt.weather",
    "按要求改变天气和时段。保持场景布局。湿润、阴影、天空和大气必须一致。",
    "按要求改變天氣和時段。保持場景佈局。濕潤、陰影、天空和大氣必須一致。",
    "指定の天候と時間帯に変えてください。レイアウトは保ち、濡れ・影・空・大気を一貫させてください。",
    "요청한 날씨와 시간대로 바꾸세요. 배치는 유지하고 젖음, 그림자, 하늘, 대기를 일관되게 하세요.")
add("ai.prompt.recolor",
    "把指定物体或蒙版区域改成指定颜色。保留材质、标志和明暗。除非要求，不要给整幅改色。",
    "把指定物體或遮罩區域改成指定顏色。保留材質、標誌和明暗。除非要求，不要給整幅改色。",
    "指定の物体またはマスク領域を指定色に再着色してください。材質・ロゴ・陰影は残し、求められない限り画面全体は再着色しないでください。",
    "지정한 물체 또는 마스크 영역을 지정 색으로 바꾸세요. 재질, 로고, 명암은 유지하고 요청이 없으면 화면 전체를 바꾸지 마세요.")
add("ai.prompt.material",
    "改变蒙版区域或主体的表面材质。保持形状、品牌和光照方向。新材质必须真实受光。",
    "改變遮罩區域或主體的表面材質。保持形狀、品牌和光照方向。新材質必須真實受光。",
    "マスク領域または被写体の材質を変え、形・ブランド・光の方向は保ってください。新しい材質は現実的に光を受けてください。",
    "마스크 영역 또는 피사체의 표면 재질을 바꾸세요. 형태, 브랜드, 빛 방향은 유지하고 새 재질은 현실적으로 빛을 받아야 합니다.")
add("ai.prompt.harmonize",
    "统一这张合成图，使各层看起来像同一次拍摄。匹配色温、对比、颗粒和光线方向。不要移动主体。",
    "統一這張合成圖，使各層看起來像同一次拍攝。匹配色溫、對比、顆粒和光線方向。不要移動主體。",
    "合成を調和させ、同じ撮影に見えるように色温度・コントラスト・粒子・光の方向を合わせてください。被写体は動かさないでください。",
    "합성을 조화시켜 한 번에 찍은 것처럼 보이게 하세요. 색온도, 대비, 그레인, 빛 방향을 맞추고 피사체는 움직이지 마세요.")
add("ai.prompt.shadow",
    "为主体添加真实的接触阴影和轻微环境光遮蔽。不要改主体。阴影必须符合现有光线。",
    "為主體添加真實的接觸陰影和輕微環境光遮蔽。不要改主體。陰影必須符合現有光線。",
    "被写体の下に現実的な接地影と弱いAOを追加し、被写体自体は変えないでください。影は既存の光に合わせてください。",
    "피사체 아래에 실제 같은 접촉 그림자와 약한 앰비언트 오클루전을 추가하세요. 피사체는 바꾸지 말고 그림자는 기존 빛에 맞추세요.")
add("ai.prompt.expand",
    "自然延伸图像超出原边界。匹配透视、光线、纹理、颗粒和颜色。接缝必须看不见。不要改照片中心，也不要沿原图矩形描边。",
    "自然延伸影像超出原邊界。匹配透視、光線、紋理、顆粒和顏色。接縫必須看不見。不要改照片中心，也不要沿原圖矩形描邊。",
    "元の境界の外へ自然に伸ばしてください。遠近・照明・質感・粒子・色を合わせ、継ぎ目は見えないように。中央の写真は変えず、元の矩形をなぞらないでください。",
    "원래 경계를 넘어 자연스럽게 확장하세요. 원근, 조명, 질감, 입자, 색을 맞추고 이음매가 보이지 않아야 합니다. 중앙 사진은 바꾸지 말고 원래 사각형을 따라 그리지 마세요.")
add("ai.prompt.fillFrame",
    "铺满整个画面。不要黑边、白边、letterbox、留白或任何外框。主体必须顶到四边。",
    "鋪滿整個畫面。不要黑邊、白邊、letterbox、留白或任何外框。主體必須頂到四邊。",
    "画面全体を埋めてください。黒帯・白帯・レターボックス・余白・枠は禁止。被写体は四辺まで達してください。",
    "화면 전체를 채우세요. 검은 테두리, 흰 테두리, 레터박스, 여백, 액자는 안 됩니다. 피사체가 네 가장자리까지 닿아야 합니다.")
add("ai.prompt.expandSeam",
    "内侧矩形是原图。不要画出这条边界，不要出现色差带或硬切。新像素必须在色温、对比和雪地颗粒上接住原图，让接缝消失。",
    "內側矩形是原圖。不要畫出這條邊界，不要出現色差帶或硬切。新像素必須在色溫、對比和雪地顆粒上接住原圖，讓接縫消失。",
    "内側の矩形が元写真です。その境界を描かず、色帯や硬い切れ目を作らないでください。色温度・コントラスト・雪の粒子を元写真に合わせ、継ぎ目を消してください。",
    "안쪽 사각형이 원본입니다. 그 경계를 그리지 말고 색띠나 하드 컷이 없게 하세요. 색온도, 대비, 눈 입자를 원본에 맞춰 이음매를 없애세요.")
add("ai.prompt.mask",
    "下一张图是编辑蒙版。透明像素是需要改动的区域；不透明像素必须保持完全一致。",
    "下一張圖是編輯遮罩。透明像素是需要改動的區域；不透明像素必須保持完全一致。",
    "次の画像は編集マスクです。透明ピクセルが変更領域、不透明ピクセルは完全に同一のままにしてください。",
    "다음 이미지는 편집 마스크입니다. 투명 픽셀이 변경 영역이고 불투명 픽셀은 완전히 동일해야 합니다.")
add("ai.prompt.selectionContext",
    "选区周围的像素是真实照片：光线、毛发、草地、透视和颜色。必须与周围场景完全衔接。不要发明新背景、棚拍或孤立剪贴画。只改蒙版/透明区域。",
    "選取範圍周圍的像素是真實照片：光線、毛髮、草地、透視和顏色。必須與周圍場景完全銜接。不要發明新背景、棚拍或孤立剪貼畫。只改遮罩/透明區域。",
    "編集領域の周囲は本物の写真です。照明・毛並み・芝生・遠近・色に合わせてください。新しい背景、スタジオ、切り抜きを作らないでください。マスク／透明部分だけを変更してください。",
    "편집 영역 주변은 실제 사진입니다. 조명, 털, 잔디, 원근, 색에 맞추세요. 새 배경, 스튜디오, 오려낸 조각은 만들지 마세요. 마스크/투명 픽셀만 바꾸세요.")
add("ai.prompt.returnEditedPhoto",
    "返回完整原图，只改蒙版区域。构图和未蒙版像素必须相同。不要返回剪贴画、贴纸，或白底/棚拍上的新物体。",
    "返回完整原圖，只改遮罩區域。構圖和未遮罩像素必須相同。不要返回剪貼畫、貼紙，或白底/棚拍上的新物體。",
    "マスク領域だけを変えた元写真全体を返してください。構図と未マスク画素は同一のまま。切り抜き、ステッカー、白背景やスタジオ上の新しい物体は返さないでください。",
    "마스크 영역만 바꾼 원본 사진 전체를 반환하세요. 구도와 마스크 밖 픽셀은 같아야 합니다. 오려낸 조각, 스티커, 흰 배경/스튜디오 위 새 물체는 반환하지 마세요.")
add("ai.prompt.noBorder",
    "不要沿选区或蒙版描边、画黑线、画矩形框或任何边框。边缘必须与周围毛发和背景无缝衔接。",
    "不要沿選取範圍或遮罩描邊、畫黑線、畫矩形框或任何邊框。邊緣必須與周圍毛髮和背景無縫銜接。",
    "選択範囲やマスクに沿って輪郭線・黒線・矩形枠を描かないでください。端は周囲の毛並みと背景に自然につないでください。",
    "선택 영역이나 마스크를 따라 윤곽선, 검은 선, 사각 테두리를 그리지 마세요. 가장자리는 주변 털과 배경에 자연스럽게 이어져야 합니다.")
add("ai.prompt.backgroundPhoto",
    "这是背景原图。",
    "這是背景原圖。",
    "これが背景の元写真です。",
    "이것이 배경 원본 사진입니다.")
add("ai.prompt.selectionMask",
    "这是选区蒙版，宽高与原图完全相同。白色是要修改的选区，黑色必须保持原样。",
    "這是選取範圍遮罩，寬高與原圖完全相同。白色是要修改的選區，黑色必須保持原樣。",
    "これが選択マスクです。幅と高さは元写真と同一です。白が編集する選択範囲、黒は元のままにしてください。",
    "이것이 선택 마스크입니다. 가로세로가 원본과 같습니다. 흰색은 수정할 선택 영역, 검은색은 그대로 두세요.")
add("ai.prompt.editInstruction",
    "修改说明：",
    "修改說明：",
    "編集指示：",
    "수정 지시:")
add("ai.prompt.selectionBounds",
    "选区在这张图中的位置是 x=%d y=%d，宽=%d 高=%d（左上角为原点）。照片为 %d × %d。请返回同样尺寸的完整照片，不要平移、缩放或裁切。",
    "選取範圍在這張圖中的位置是 x=%d y=%d，寬=%d 高=%d（左上角為原點）。照片為 %d × %d。請返回同樣尺寸的完整照片，不要平移、縮放或裁切。",
    "この画像内の選択範囲は x=%d y=%d、幅=%d 高さ=%d（原点は左上）です。写真は %d × %d です。同じサイズの写真全体を返し、平行移動・拡大縮小・切り抜きはしないでください。",
    "이 이미지에서 선택 영역은 x=%d y=%d, 너비=%d 높이=%d(원점은 왼쪽 위)입니다. 사진은 %d × %d입니다. 같은 크기의 전체 사진을 반환하고 이동, 확대/축소, 자르기는 하지 마세요.")

add("Merge Down", "向下合并", "向下合併", "下のレイヤーと結合", "아래로 병합")
add("Merge Layers", "合并图层", "合併圖層", "レイヤーを結合", "레이어 병합")
add("Merge Group", "合并组", "合併群組", "グループを結合", "그룹 병합")
add("API key works.", "API 密钥可用。", "API 金鑰可用。", "APIキーは有効です。", "API 키가 유효합니다.")
add("API key works. %d models are visible on this account.",
    "API 密钥可用。此账号可见 %d 个模型。",
    "API 金鑰可用。此帳號可見 %d 個模型。",
    "APIキーは有効です。このアカウントでは%d個のモデルが見えます。",
    "API 키가 유효합니다. 이 계정에서 모델 %d개가 보입니다.")
add("The API key could not be locked to this Mac (Keychain status %d).",
    "无法把 API 密钥锁定到这台 Mac（钥匙串状态 %d）。",
    "無法把 API 金鑰鎖定到這台 Mac（鑰匙圈狀態 %d）。",
    "APIキーをこのMacにロックできませんでした（キーチェーン状態 %d）。",
    "API 키를 이 Mac에 잠글 수 없습니다(키체인 상태 %d).")
add("The saved API credentials file is damaged and cannot be read.",
    "已保存的 API 凭据文件已损坏，无法读取。",
    "已儲存的 API 憑證檔案已損壞，無法讀取。",
    "保存済みのAPI認証ファイルが破損していて読み取れません。",
    "저장된 API 자격 증명 파일이 손상되어 읽을 수 없습니다.")
add("Enter a valid Base URL, such as https://zenmux.ai/api/v1.",
    "请输入有效的 Base URL，例如 https://zenmux.ai/api/v1。",
    "請輸入有效的 Base URL，例如 https://zenmux.ai/api/v1。",
    "https://zenmux.ai/api/v1 のような有効なベースURLを入力してください。",
    "https://zenmux.ai/api/v1 같은 유효한 Base URL을 입력하세요.")

# AI help
add("Creates a new layer from a text prompt. With no canvas open, the image becomes the document.",
    "根据文字提示创建新图层。若未打开画布，生成的图像会成为文档。",
    "根據文字提示建立新圖層。若未開啟畫布，產生的影像會成為文件。",
    "テキストから新規レイヤーを作ります。キャンバスが無い場合、画像がドキュメントになります。",
    "텍스트 프롬프트로 새 레이어를 만듭니다. 캔버스가 없으면 이미지가 문서가 됩니다.")
add("Paints a new interpretation of the current canvas onto a new layer.",
    "把当前画布的新诠释画到一个新图层上。",
    "把目前畫布的新詮釋畫到一個新圖層上。",
    "現在のキャンバスの新しい解釈を新規レイヤーに描きます。",
    "현재 캔버스의 새로운 해석을 새 레이어에 그립니다.")
add("Generates a tile-friendly texture or pattern as a new layer.",
    "生成适合平铺的纹理或图案，作为新图层。",
    "產生適合平鋪的紋理或圖案，作為新圖層。",
    "タイル向きのテクスチャやパターンを新規レイヤーとして生成します。",
    "타일링에 적합한 텍스처나 패턴을 새 레이어로 생성합니다.")
add("Builds a layout-heavy graphic with readable type, good for Qwen.",
    "生成版式感强、文字可读的图形，适合 Qwen。",
    "產生版式感強、文字可讀的圖形，適合 Qwen。",
    "読みやすい文字のレイアウト重視グラフィックを作ります。Qwen向きです。",
    "읽기 쉬운 글자가 있는 레이아웃 그래픽을 만듭니다. Qwen에 적합합니다.")
add("Keeps the composition and redraws it in another medium or look.",
    "保持构图，用另一种媒介或风格重绘。",
    "保持構圖，用另一種媒介或風格重繪。",
    "構図を保ったまま別の画材や見た目で描き直します。",
    "구도를 유지한 채 다른 매체나 분위기로 다시 그립니다.")
add("Turns line work or a rough block-in into a finished picture.",
    "把线稿或粗略铺色变成完成图。",
    "把線稿或粗略鋪色變成完成圖。",
    "線画やラフを完成した絵にします。",
    "선화나 러프를 완성된 그림으로 바꿉니다.")
add("Adds plausible color to a black-and-white or faded image.",
    "为黑白或褪色图像补上合理颜色。",
    "為黑白或褪色影像補上合理顏色。",
    "白黒や色褪せた画像に妥当な色を付けます。",
    "흑백이거나 바랜 이미지에 자연스러운 색을 입힙니다.")
add("Changes the lighting direction and quality without rebuilding the scene.",
    "不重建场景，只改变光线方向与质感。",
    "不重建場景，只改變光線方向與質感。",
    "シーンを作り直さず、光の方向と質だけを変えます。",
    "장면을 다시 만들지 않고 빛의 방향과 질만 바꿉니다.")
add("Returns a sharper, higher-resolution layer displayed at the original size.",
    "返回更清晰、更高分辨率的图层，仍按原尺寸显示。",
    "返回更清晰、更高解析度的圖層，仍按原尺寸顯示。",
    "よりシャープで高解像度のレイヤーを元の表示サイズで返します。",
    "더 선명하고 고해상도인 레이어를 원래 표시 크기로 반환합니다.")
add("Removes dust, compression, and mild blur while keeping the photo honest.",
    "去掉灰尘、压缩痕迹和轻微模糊，同时保持照片真实。",
    "去掉灰塵、壓縮痕跡和輕微模糊，同時保持照片真實。",
    "ホコリ・圧縮・軽いボケを取り除き、写真の正直さは保ちます。",
    "먼지, 압축 노이즈, 약한 흐림을 제거하되 사진의 진솔함은 유지합니다.")
add("Repairs scratches, stains, and fading on archival photographs.",
    "修复档案照片上的划痕、污渍和褪色。",
    "修復檔案照片上的刮痕、污漬和褪色。",
    "保存写真の傷、シミ、色褪せを修復します。",
    "기록 사진의 긁힘, 얼룩, 바램을 복원합니다.")
add("Edits the current layer in place. Only the selected pixels change; nothing new is added to the Layers list.",
    "在当前图层上就地修改。只改选区内的像素，不会新增图层。",
    "在目前圖層上就地修改。只改選取範圍內的像素，不會新增圖層。",
    "現在のレイヤーを直接編集します。選択内のピクセルだけが変わり、新しいレイヤーは追加しません。",
    "현재 레이어를 제자리에서 수정합니다. 선택 영역 픽셀만 바뀌고 새 레이어는 생기지 않습니다.")
add("Erases whatever is inside the selection and rebuilds a matching background.",
    "擦除选区内的内容并重建匹配的背景。",
    "擦除選取範圍內的內容並重建匹配的背景。",
    "選択内のものを消し、周囲に合う背景を再構築します。",
    "선택 안을 지우고 어울리는 배경을 다시 만듭니다.")
add("Clears pen marks and signatures. Printed type and graphics are kept.",
    "清除笔迹和签名，保留印刷文字与图形。",
    "清除筆跡和簽名，保留印刷文字與圖形。",
    "手書きと署名を消し、印刷文字と図は残します。",
    "필기와 서명을 지우고 인쇄 글자와 그래픽은 남깁니다.")
add("Removes captions, labels, and overlaid type. A selection limits the pass.",
    "去除标题、标签和叠加文字。选区可限制范围。",
    "去除標題、標籤和疊加文字。選取範圍可限制範圍。",
    "キャプション、ラベル、重ね文字を除去します。選択で範囲を限定できます。",
    "캡션, 라벨, 겹친 글자를 제거합니다. 선택 영역으로 범위를 제한할 수 있습니다.")
add("Keeps the subject and builds a new environment behind it.",
    "保留主体，在其背后生成新环境。",
    "保留主體，在其背後產生新環境。",
    "被写体を残し、背後に新しい環境を作ります。",
    "피사체는 유지하고 뒤에 새 환경을 만듭니다.")
add("Replaces only the sky and the light it throws on the scene.",
    "只替换天空及其投射到场景上的光。",
    "只替換天空及其投射到場景上的光。",
    "空と、それがシーンに落とす光だけを置き換えます。",
    "하늘과 그것이 장면에 던지는 빛만 바꿉니다.")
add("Changes weather and time of day across the frame or the selection.",
    "改变整幅或选区内的天气与时段。",
    "改變整幅或選取範圍內的天氣與時段。",
    "画面全体または選択範囲の天候と時刻を変えます。",
    "프레임 또는 선택 영역의 날씨와 시간을 바꿉니다.")
add("Shifts the color of the selected object while keeping material and shading.",
    "改变所选物体的颜色，保留材质与明暗。",
    "改變所選物體的顏色，保留材質與明暗。",
    "選択した物体の色だけを変え、材質と陰影は保ちます。",
    "선택한 물체의 색만 바꾸고 재질과 음영은 유지합니다.")
add("Keeps the object's shape and assigns a new surface.",
    "保持物体形状，赋予新表面材质。",
    "保持物體形狀，賦予新表面材質。",
    "形は保ったまま新しい表面を与えます。",
    "물체 형태는 유지하고 새 표면을 입힙니다.")
add("Matches lighting and color so a composite looks like one photograph.",
    "统一光色，让合成看起来像一张照片。",
    "統一光色，讓合成看起來像一張照片。",
    "照明と色を合わせて、合成を一枚の写真に見せます。",
    "조명과 색을 맞춰 합성이 한 장의 사진처럼 보이게 합니다.")
add("Adds a grounded contact shadow under the subject.",
    "在主体下方添加贴地接触阴影。",
    "在主體下方新增貼地接觸陰影。",
    "被写体の下に接地したコンタクトシャドウを加えます。",
    "피사체 아래에 땅에 붙는 접촉 그림자를 넣습니다.")
add("Grows the canvas and paints the new borders so they continue the picture.",
    "扩大画布并绘制新边，使画面自然延续。",
    "擴大畫布並繪製新邊，使畫面自然延續。",
    "キャンバスを広げ、新しい余白を絵の続きとして描きます。",
    "캔버스를 키우고 새 가장자리를 그림의 연장으로 그립니다.")

# AI placeholders
add("A sunlit studio still life of citrus on linen, soft shadows, 50mm photograph",
    "阳光工作室里亚麻布上的柑橘静物，柔和阴影，50mm 照片",
    "陽光工作室裡亞麻布上的柑橘靜物，柔和陰影，50mm 照片",
    "リネンの上の柑橘のスタジオ静物、柔らかい影、50mm写真",
    "리넨 위 감귤 정물, 부드러운 그림자, 50mm 사진")
add("Optional: lean warmer, wider, or more cinematic",
    "可选：更暖、更宽，或更电影感",
    "可選：更暖、更寬，或更電影感",
    "任意：より暖色、広角、映画的に",
    "선택: 더 따뜻하거나, 더 넓거나, 더 영화적으로")
add("Seamless terrazzo in cream and moss, 8K texture",
    "奶油色与苔绿无缝水磨石，8K 纹理",
    "奶油色與苔綠無縫水磨石，8K 紋理",
    "クリームと苔色の継ぎ目なしテラゾ、8Kテクスチャ",
    "크림과 이끼색 심리스 테라조, 8K 텍스처")
add("A concert poster, bold condensed type, two-color print",
    "演唱会海报，粗壮压缩字体，双色印刷",
    "演唱會海報，粗壯壓縮字體，雙色印刷",
    "コンサートポスター、太いコンデンス書体、2色印刷",
    "콘서트 포스터, 굵은 압축 서체, 2색 인쇄")
add("Oil painting, watercolor, editorial photo, anime…",
    "油画、水彩、杂志摄影、动漫…",
    "油畫、水彩、雜誌攝影、動漫…",
    "油絵、水彩、エディトリアル写真、アニメ…",
    "유화, 수채, 화보 사진, 애니메이션…")
add("Turn this sketch into a finished product photo",
    "把这张草图变成完成的产品照片",
    "把這張草圖變成完成的產品照片",
    "このスケッチを完成した製品写真に",
    "이 스케치를 완성된 제품 사진으로")
add("Optional: period-accurate 1970s film colors",
    "可选：符合 1970 年代胶片的色彩",
    "可選：符合 1970 年代膠片的色彩",
    "任意：1970年代フィルムに忠実な色",
    "선택: 1970년대 필름에 맞는 색")
add("Soft window light, rim light, golden hour…",
    "柔和窗光、轮廓光、黄金时刻…",
    "柔和窗光、輪廓光、黃金時刻…",
    "柔らかい窓光、リムライト、ゴールデンアワー…",
    "부드러운 창빛, 림라이트, 골든아워…")
add("Optional: recover fine fabric and type",
    "可选：恢复细腻织物与文字",
    "可選：恢復細膩織物與文字",
    "任意：細かな生地と文字を復元",
    "선택: 섬세한 직물과 글자를 복원")
add("Optional: keep grain, only remove dust",
    "可选：保留颗粒，只去灰尘",
    "可選：保留顆粒，只去灰塵",
    "任意：粒子は残し、ホコリだけ除去",
    "선택: 그레인은 남기고 먼지만 제거")
add("Optional: heal tears, keep the original paper",
    "可选：修补撕裂，保留原纸质感",
    "可選：修補撕裂，保留原紙質感",
    "任意：破れを直し、元の紙を残す",
    "선택: 찢어진 곳은 고치고 원래 종이는 유지")
add("Optional: what should appear in the selection",
    "可选：选区里应该出现什么",
    "可選：選取範圍裡應該出現什麼",
    "任意：選択内に何を出すか",
    "선택: 선택 영역에 무엇이 나와야 하는지")
add("Optional: describe the object if the selection is loose",
    "可选：选区较松时描述要去掉的物体",
    "可選：選取範圍較鬆時描述要去掉的物體",
    "任意：選択が粗い場合は物体を説明",
    "선택: 선택이 느슨하면 물체를 설명")
add("Optional: keep stamps or page texture",
    "可选：保留印章或纸面纹理",
    "可選：保留印章或紙面紋理",
    "任意：スタンプや紙の質感を残す",
    "선택: 도장이나 종이 질감 유지")
add("Optional: keep logos or captions you still need",
    "可选：保留仍需要的标志或说明",
    "可選：保留仍需要的標誌或說明",
    "任意：残したいロゴやキャプション",
    "선택: 남겨야 할 로고나 캡션")
add("Seamless white studio, cedar forest, marble lobby…",
    "无缝白棚、雪松林、大理石大堂…",
    "無縫白棚、雪松林、大理石大廳…",
    "継ぎ目なし白ホリゾ、杉の森、大理石ロビー…",
    "심리스 화이트 스튜디오, 삼나무 숲, 대리석 로비…")
add("Clear dusk, storm, sunset with long clouds…",
    "晴朗黄昏、暴风雨、长云晚霞…",
    "晴朗黃昏、暴風雨、長雲晚霞…",
    "晴れの黄昏、嵐、長い雲の夕焼け…",
    "맑은 황혼, 폭풍, 긴 구름 노을…")
add("Rain at night, snowfall, dense fog…",
    "夜雨、降雪、浓雾…",
    "夜雨、降雪、濃霧…",
    "夜の雨、降雪、濃霧…",
    "밤비, 강설, 짙은 안개…")
add("Matte sage green, cherry red lacquer…",
    "哑光鼠尾草绿、樱桃红漆…",
    "霧面鼠尾草綠、櫻桃紅漆…",
    "マットなセージグリーン、朱塗りの赤…",
    "매트 세이지 그린, 체리 레드 래커…")
add("Brushed aluminum, frosted glass, oak…",
    "拉丝铝、磨砂玻璃、橡木…",
    "拉絲鋁、磨砂玻璃、橡木…",
    "ブラッシュドアルミ、すりガラス、オーク…",
    "브러시드 알루미늄, 프로스티드 글라스, 오크…")
add("Optional: match a cooler moonlight grade",
    "可选：匹配更冷的月光调色",
    "可選：匹配更冷的月光調色",
    "任意：より冷たい月明かりのグレーディング",
    "선택: 더 차가운 달빛 그레이딩")
add("Optional: longer late-afternoon shadow",
    "可选：更长的傍晚阴影",
    "可選：更長的傍晚陰影",
    "任意：より長い夕方の影",
    "선택: 더 긴 늦은 오후 그림자")
add("Optional: what the new borders should become",
    "可选：新边界应该变成什么",
    "可選：新邊界應該變成什麼",
    "任意：新しい余白を何にするか",
    "선택: 새 가장자리가 무엇이 되어야 하는지")

# JPEG / canvas size
add("Export JPEG", "导出 JPEG", "匯出 JPEG", "JPEGを書き出す", "JPEG보내기")
add("Canvas Size", "画布大小", "畫布大小", "キャンバスサイズ", "캔버스 크기")
add("Image Size", "图像大小", "影像大小", "画像サイズ", "이미지 크기")
add("Units", "单位", "單位", "単位", "단위")
add("Pixels", "像素", "像素", "ピクセル", "픽셀")
add("Percent", "百分比", "百分比", "パーセント", "퍼센트")
add("Inches", "英寸", "英吋", "インチ", "인치")
add("Centimeters", "厘米", "公分", "センチメートル", "센티미터")
add("Relative to current dimensions", "相对当前尺寸", "相對目前尺寸", "現在のサイズからの相対値", "현재 크기 기준")
add("Lock original aspect ratio", "锁定原始比例", "鎖定原始比例", "元の縦横比を固定", "원래 비율 잠금")
add("Transform", "变换", "變形", "変形", "변형")
add("Transform Mask", "变换蒙版", "變形遮罩", "マスクを変形", "마스크 변형")
add("Show Controls", "显示控件", "顯示控制項", "コントロールを表示", "컨트롤 표시")
add("Flip H", "水平翻转", "水平翻轉", "水平反転", "가로 뒤집기")
add("Flip V", "垂直翻转", "垂直翻轉", "垂直反転", "세로 뒤집기")
add("Freehand", "自由套索", "自由套索", "フリーハンド", "자유")
add("Polygonal", "多边形", "多邊形", "多角形", "다각형")
add("Rectangle", "矩形", "矩形", "矩形", "사각형")
add("Ellipse", "椭圆", "橢圓", "楕円", "타원")

register_extra(add)

EN_SOURCE = {
    "ai.prompt.variation": "Create a fresh variation of this image. Keep the same subject and composition, but change details, styling, and atmosphere enough that it is clearly a new take. Do not add captions.",
    "ai.prompt.restyle": "Redraw this image in the requested style. Preserve composition, subject identity, and readable text. The style applies to medium, lighting, and finish.",
    "ai.prompt.sketch": "Turn this sketch or rough layout into a finished, photoreal or polished illustration. Respect the lines and proportions. Invent plausible materials and lighting.",
    "ai.prompt.colorize": "Colorize this image with natural, historically plausible colors. Keep edges sharp, do not invent new objects, and preserve existing tones that are already colored.",
    "ai.prompt.relight": "Relight this image as requested. Keep geometry, identity, and text unchanged. Update shadows, highlights, and reflected light so they match the new lighting.",
    "ai.prompt.enhance": "Enhance this image: increase apparent resolution, recover fine texture and type, reduce artifacts, and keep the original look. Do not change composition or add objects.",
    "ai.prompt.cleanup": "Clean this image: remove dust, specks, compression blocks, and mild blur. Do not beautify faces, do not recompose, and keep authentic grain if present.",
    "ai.prompt.restore": "Restore this damaged photograph. Repair scratches, tears, stains, and fading. Preserve identity and period character. Do not modernize clothing or backgrounds.",
    "ai.prompt.fill": "Fill the transparent / masked region so it matches the surrounding image. Keep lighting, perspective, texture, and style consistent. Do not change opaque areas.",
    "ai.prompt.removeObject": "Remove the object in the transparent / masked region and reconstruct a natural background that matches the surroundings. Leave no trace of the object or its shadow.",
    "ai.prompt.handwriting": "Remove handwritten marks, signatures, ink strokes, doodles, and pen annotations. Preserve all printed text, typography, stamps, and printed graphics exactly. Keep paper texture.",
    "ai.prompt.removeText": "Remove overlaid text, captions, watermarks made of type, and labels. Reconstruct the background. Preserve logos and graphics that are part of the original scene unless they are clearly added captions.",
    "ai.prompt.replaceBackground": "Replace the background behind the main subject. Keep the subject, hair, and contact edges intact. Match lighting on the subject to the new environment. No extra people.",
    "ai.prompt.replaceSky": "Replace the sky only. Keep the horizon, buildings, and foliage. Update the light on the land so it matches the new sky. Do not move the camera.",
    "ai.prompt.weather": "Change the weather and time of day as requested. Keep the scene layout. Update wetness, shadows, sky, and atmosphere consistently.",
    "ai.prompt.recolor": "Recolor the requested object or the masked region to the specified color. Keep material, logos, and shading. Do not recolor the whole frame unless asked.",
    "ai.prompt.material": "Change the surface material of the object in the masked region or the main subject. Keep shape, branding, and lighting direction. The new material should catch light realistically.",
    "ai.prompt.harmonize": "Harmonize this composite so every layer looks shot together. Match color temperature, contrast, grain, and light direction. Do not move subjects.",
    "ai.prompt.shadow": "Add a realistic contact shadow and gentle ambient occlusion under the main subject. Do not alter the subject. Keep the shadow consistent with existing light.",
    "ai.prompt.expand": "Extend the image naturally beyond its original borders. Match perspective, lighting, texture, grain, and color. The join must be invisible. Do not alter the center photograph, and do not stroke the original rectangle.",
    "ai.prompt.expandSeam": "The inner rectangle is the original photograph. Do not draw that border. Do not leave a color band or a hard cut. New pixels must match the original's white balance, contrast, and snow grain so the seam disappears.",
    "ai.prompt.fillFrame": "Fill the entire frame. No black bars, white bars, letterboxing, padding, or any border. The subject must reach all four edges.",
    "ai.prompt.mask": "The following image is an edit mask. Transparent pixels are the region to change; opaque pixels must stay identical.",
    "ai.prompt.selectionContext": "The pixels around the edit region are the real photograph — lighting, fur, grass, perspective, and color. Match that surrounding scene exactly. Do not invent a new backdrop, studio, or isolated cutout. Change only the masked / transparent pixels.",
    "ai.prompt.returnEditedPhoto": "Return the complete original photograph with only the masked region changed. Same framing and unmasked pixels. Do not return a cutout, sticker, or a new object on a blank or studio background.",
    "ai.prompt.noBorder": "Do not stroke the selection or mask. Do not draw black lines, rectangles, or any frame around the edit. The edge must continue the surrounding fur and background with no seam.",
    "ai.prompt.backgroundPhoto": "This is the background photograph.",
    "ai.prompt.selectionMask": "This is the selection mask. It has the exact same width and height as the photograph. White pixels are the selected region to edit; black pixels must stay identical.",
    "ai.prompt.editInstruction": "Edit instruction:",
    "ai.prompt.selectionBounds": "The selected region in this image is x=%d y=%d width=%d height=%d, origin top-left. The photograph is %d × %d. Return the full image at that same size. Do not shift, scale, or crop.",
}

out = {
    "sourceLanguage": "en",
    "strings": {},
    "version": "1.0",
}
for key, locs in T.items():
    entry = {"localizations": {}}
    english = EN_SOURCE.get(key)
    if english:
        entry["localizations"]["en"] = {"stringUnit": {"state": "translated", "value": english}}
    for lang, value in locs.items():
        entry["localizations"][lang] = {"stringUnit": {"state": "translated", "value": value}}
    out["strings"][key] = entry

path = Path(__file__).resolve().parents[1] / "Compositor" / "Localizable.xcstrings"
path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {len(T)} keys -> {path}")
