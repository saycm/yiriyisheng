
import json
import subprocess
from pathlib import Path

root = Path(r"E:/claudecode/pingsheng_life_source")
out_dir = root / "tmp" / "workout_gen"
out_dir.mkdir(parents=True, exist_ok=True)
script = Path(r"C:/Users/Administrator/.codex/skills/agnes-ai-generation-skill/scripts/agnes_api.py")

jobs = [
    {
        "slug": "chest",
        "filename": "sheet_chest.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different chest or back gym movement with accurate posture and visible equipment, in this exact left-to-right top-to-bottom order: 1 butterfly chest fly machine, 2 wide-grip lat pulldown, 3 machine chest press, 4 seated cable row, 5 incline dumbbell press, 6 one-arm dumbbell row, 7 bent-over barbell row. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
    {
        "slug": "shoulder",
        "filename": "sheet_shoulder.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different shoulder or neck gym movement with accurate posture and visible equipment, in this exact left-to-right top-to-bottom order: 1 dumbbell lateral raise, 2 dumbbell front raise, 3 standing overhead press, 4 cable face pull, 5 reverse fly, 6 dumbbell shrug, 7 resistance band external rotation. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
    {
        "slug": "core",
        "filename": "sheet_core.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different core exercise with accurate posture, in this exact left-to-right top-to-bottom order: 1 plank, 2 dead bug, 3 Russian twist, 4 lying leg raise, 5 crunch knee touch, 6 mountain climber, 7 side plank. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
    {
        "slug": "legs",
        "filename": "sheet_legs.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different leg or glute gym movement with accurate posture and visible equipment, in this exact left-to-right top-to-bottom order: 1 barbell squat, 2 Bulgarian split squat, 3 Romanian deadlift, 4 hip thrust, 5 leg press, 6 box step-up, 7 seated leg extension. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
    {
        "slug": "cardio",
        "filename": "sheet_cardio.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different cardio workout with accurate posture and visible equipment, in this exact left-to-right top-to-bottom order: 1 treadmill jogging, 2 rowing machine sprint, 3 spinning bike, 4 elliptical training, 5 jump rope, 6 stair climber, 7 burpee. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
    {
        "slug": "stretch",
        "filename": "sheet_stretch.png",
        "prompt": "A fitness app asset sheet made of eight equal rounded-square instruction cards arranged in a clean 4 by 2 grid on a white canvas with even spacing. Card 8 in the bottom-right is an empty pale blue placeholder with no athlete. Cards 1 to 7 each show exactly one full-body athlete performing a different stretching movement with accurate posture, in this exact left-to-right top-to-bottom order: 1 standing quadriceps stretch, 2 seated hamstring stretch, 3 kneeling hip flexor stretch, 4 doorway chest stretch, 5 cat-cow stretch, 6 child pose, 7 neck side stretch. Consistent modern flat illustration style, soft blue and white palette, crisp outlines, no text, no watermark, centered composition inside each card, app-icon friendly."
    },
]

results = []
for job in jobs:
    cmd = [
        "python", str(script), "image",
        "--prompt", job["prompt"],
        "--size", "1536x1024",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(proc.stdout)
    url = data["urls"][0]
    dest = out_dir / job["filename"]
    subprocess.run([
        "powershell", "-Command",
        f'Invoke-WebRequest -Uri "{url}" -OutFile "{dest}"'
    ], check=True)
    results.append({"slug": job["slug"], "path": str(dest), "url": url})

print(json.dumps(results, ensure_ascii=False, indent=2))
