import os

filepath = 'World/Room1.tscn'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

ext_lines = []
for i, line in enumerate(lines):
    if line.startswith('[ext_resource'):
        ext_lines.append(i)

if ext_lines:
    last_ext_idx = ext_lines[-1]
    new_ext = '[ext_resource type="PackedScene" path="res://World/LevelTransition.tscn" id="99_trans"]\n'
    lines.insert(last_ext_idx + 1, new_ext)

lines.append('\n[node name="LevelTransition" parent="." instance=ExtResource("99_trans")]\n')
lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 100, 0)\n')
lines.append('next_level_path = "res://World/Finale.tscn"\n')

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(lines)
