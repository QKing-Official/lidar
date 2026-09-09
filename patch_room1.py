import os

filepath = 'World/Room1.tscn'
if not os.path.exists(filepath):
    print("File not found")
    exit(1)

with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('res://World/Finale.tscn', 'res://World/Room2.tscn')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated Room1.tscn to point to Room2.tscn")
