import hashlib
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "animations")

SHEETS = [
    {
        "name": "middleaged_white_walk",
        "file": "middleaged_white_walk_spritesheet.png",
        "tex_uid": "uid://rtncaaw02y1p",
        "frames": 8,
        "cell_w": 84,
        "walk_fps": 12.0,
    },
    {
        "name": "muslim_walk",
        "file": "muslim_walk_sheet.png",
        "tex_uid": "uid://c6265na7jk30a",
        "frames": 8,
        "cell_w": 64,
        "walk_fps": 12.0,
    },
    {
        "name": "obese_woman_walk",
        "file": "obese_woman_walk_spritesheet.png",
        "tex_uid": "uid://coomv7dvjmkel",
        "frames": 16,
        "cell_w": 100,
        "walk_fps": 14.0,
    },
    {
        "name": "slim_black2_walk",
        "file": "slim_black_sprite2_walk_sheet.png",
        "tex_uid": "uid://s0oo1u2q2k2h",
        "frames": 8,
        "cell_w": 104,
        "walk_fps": 12.0,
    },
    {
        "name": "slim_black_walk",
        "file": "slim_black_sprite_walking_sheet.png",
        "tex_uid": "uid://5r4k2c76uycn",
        "frames": 8,
        "cell_w": 74,
        "walk_fps": 12.0,
    },
    {
        "name": "slim_pakistani_walk",
        "file": "slim_pakistani_walk_spritesheet.png",
        "tex_uid": "uid://hu4rhb1koo6y",
        "frames": 8,
        "cell_w": 64,
        "walk_fps": 12.0,
    },
    {
        "name": "small_figure_walk",
        "file": "small_figure_walk_spritesheet.png",
        "tex_uid": "uid://c3eu7pm080ynr",
        "frames": 12,
        "cell_w": 80,
        "walk_fps": 12.0,
    },
    {
        "name": "young_man_walk",
        "file": "young_man_walk_spritesheet.png",
        "tex_uid": "uid://183gpda2bwdh",
        "frames": 12,
        "cell_w": 64,
        "walk_fps": 12.0,
    },
    {
        "name": "young_slim_walk",
        "file": "young_slim_walk_spritesheet.png",
        "tex_uid": "uid://spadtkq701k8",
        "frames": 12,
        "cell_w": 74,
        "walk_fps": 12.0,
    },
]


def make_uid(name: str) -> str:
    n = int(hashlib.sha1(name.encode()).hexdigest()[:16], 16)
    alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    chars = []
    for _ in range(13):
        chars.append(alphabet[n % 36])
        n //= 36
    return "uid://" + "".join(chars)


def atlas_block(i: int, cell_w: int) -> str:
    x = i * cell_w
    return (
        f'[sub_resource type="AtlasTexture" id="walk_{i}"]\n'
        f'atlas = ExtResource("1_sheet")\n'
        f"region = Rect2({x}, 0, {cell_w}, 128)\n"
        "filter_clip = true\n"
    )


def frame_list(indices: list[int]) -> str:
    parts = []
    for i in indices:
        parts.append(
            "{\n"
            '"duration": 1.0,\n'
            f'"texture": SubResource("walk_{i}")\n'
            "}"
        )
    return ", ".join(parts)


def strike_frames(n: int) -> list[int]:
    mid = n // 2
    raw = [max(0, mid - 1), mid, min(n - 1, mid + 1), min(n - 1, mid + 2)]
    unique: list[int] = []
    seen: set[int] = set()
    for i in raw:
        if i not in seen:
            seen.add(i)
            unique.append(i)
    return unique


def main() -> None:
    out_dir = os.path.abspath(OUT_DIR)
    os.makedirs(out_dir, exist_ok=True)
    for sheet in SHEETS:
        n = sheet["frames"]
        cell_w = sheet["cell_w"]
        res_uid = make_uid(sheet["name"])
        strike = strike_frames(n)
        blocks = [atlas_block(i, cell_w) for i in range(n)]
        anims = [
            "{\n"
            '"frames": [' + frame_list([0]) + "],\n"
            '"loop": 1,\n'
            '"name": &"idle",\n'
            '"speed": 1.0\n'
            "}",
            "{\n"
            '"frames": [' + frame_list(strike) + "],\n"
            '"loop": 0,\n'
            '"name": &"strike",\n'
            '"speed": 16.0\n'
            "}",
            "{\n"
            '"frames": [' + frame_list(list(range(n))) + "],\n"
            '"loop": 1,\n'
            '"name": &"walk",\n'
            f'"speed": {sheet["walk_fps"]}\n'
            "}",
        ]
        text = (
            f'[gd_resource type="SpriteFrames" format=3 uid="{res_uid}"]\n\n'
            f'[ext_resource type="Texture2D" uid="{sheet["tex_uid"]}" '
            f'path="res://assets/spritesheets/{sheet["file"]}" id="1_sheet"]\n\n'
            + "\n".join(blocks)
            + "\n[resource]\n"
            + "animations = ["
            + ", ".join(anims)
            + "]\n"
        )
        path = os.path.join(out_dir, sheet["name"] + ".tres")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        print(f"{sheet['name']}.tres uid={res_uid} frames={n} cell={cell_w} strike={strike}")


if __name__ == "__main__":
    main()
