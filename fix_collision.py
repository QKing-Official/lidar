import re

with open('Rooms/Room1.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add StaticBody3D node right after the root node
# Instead of matching the exact string, let's use a regex to find the root node instance line
pattern_root = r'(\[node name="Jamjam map tmp new".*?\])'
static_body_str = '\n[node name="MazeCollision" type="StaticBody3D" parent="."]\n'

content = re.sub(pattern_root, r'\1' + static_body_str, content, count=1)

# 2. Change parent="." to parent="MazeCollision" for all CollisionShape3D nodes
content = re.sub(r'(\[node name="CollisionShape3D.*?)parent="\."', r'\1parent="MazeCollision"', content)

with open('Rooms/Room1.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed Room1.tscn!')
