import json
import struct
import base64
import os
import sys

def parse_glb(filepath):
    with open(filepath, 'rb') as f:
        magic = f.read(4)
        if magic != b'glTF':
            return None
        version, length = struct.unpack('<II', f.read(8))
        
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        json_data = f.read(chunk_len)
        gltf = json.loads(json_data)
        
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        bin_data = f.read(chunk_len)
        
    return gltf, bin_data

def get_vertices(gltf, bin_data, accessor_idx):
    accessor = gltf['accessors'][accessor_idx]
    buffer_view = gltf['bufferViews'][accessor['bufferView']]
    
    byte_offset = accessor.get('byteOffset', 0) + buffer_view.get('byteOffset', 0)
    count = accessor['count']
    
    vertices = []
    for i in range(count):
        offset = byte_offset + i * 12
        x, y, z = struct.unpack('<fff', bin_data[offset:offset+12])
        vertices.append((x, y, z))
    return vertices

def generate_tscn(entity_name, model_file, script_file, flip_y=False):
    glb_path = f'Entities/{model_file}'
    gltf, bin_data = parse_glb(glb_path)
    
    tscn = f"""[gd_scene load_steps=10 format=3 uid="uid://{entity_name.lower()}uid3"]

[ext_resource type="Script" path="res://Entities/{script_file}" id="1_script"]
[ext_resource type="PackedScene" path="res://Entities/{model_file}" id="2_model"]
"""
    
    nodes_tscn = f"""[node name="{entity_name}" type="CharacterBody3D" groups=["enemy"]]
script = ExtResource("1_script")

[node name="{entity_name}Model" parent="." instance=ExtResource("2_model")]
"""
    if flip_y:
        nodes_tscn += 'transform = Transform3D(1, 0, 0, 0, -1, 8.74228e-08, 0, -8.74228e-08, -1, 0, 0, 0)\n'
        
    shape_idx = 1
    for node in gltf.get('nodes', []):
        if 'mesh' in node:
            mesh_idx = node['mesh']
            mesh = gltf['meshes'][mesh_idx]
            
            all_verts = []
            for primitive in mesh['primitives']:
                pos_acc = primitive['attributes'].get('POSITION')
                if pos_acc is not None:
                    all_verts.extend(get_vertices(gltf, bin_data, pos_acc))
            
            # Apply node transform
            t = node.get('translation', [0,0,0])
            r = node.get('rotation', [0,0,0,1]) # quaternion
            s = node.get('scale', [1,1,1])
            
            # For ConvexPolygonShape3D, we just dump points. Godot will compute convex hull.
            # But wait, Godot's ConvexPolygonShape3D needs the points of the convex hull, not all points.
            # Giving all points works, but it's inefficient.
            # However, for a small mesh, it's fine.
            
            pts_str = ", ".join([f"{v[0]} {v[1]} {v[2]}" for v in all_verts])
            # Wait, Godot points format: x, y, z, x, y, z...
            pts_array = []
            for v in all_verts:
                # scale
                vx = v[0] * s[0]
                vy = v[1] * s[1]
                vz = v[2] * s[2]
                
                # apply quaternion rotation
                qx, qy, qz, qw = r
                # simplified rotation (assuming mostly identity or pure axis for now, but let's just do full math)
                # v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v)
                tx = 2.0 * (qy * vz - qz * vy)
                ty = 2.0 * (qz * vx - qx * vz)
                tz = 2.0 * (qx * vy - qy * vx)
                rx = vx + qw * tx + (qy * tz - qz * ty)
                ry = vy + qw * ty + (qz * tx - qx * tz)
                rz = vz + qw * tz + (qx * ty - qy * tx)
                
                # translation
                fx = rx + t[0]
                fy = ry + t[1]
                fz = rz + t[2]
                
                pts_array.extend([fx, fy, fz])
            
            # Subsample points if there are too many (Godot limit is usually fine, but to be safe)
            if len(pts_array) > 3000:
                pts_array = pts_array[::3]
                
            pts_str = ", ".join([str(round(p, 4)) for p in pts_array])
            
            tscn += f"""
[sub_resource type="ConvexPolygonShape3D" id="ConvexPolygonShape3D_{shape_idx}"]
points = PackedVector3Array({pts_str})
"""
            
            # Add CollisionShape3D
            nodes_tscn += f"""
[node name="CollisionShape3D_{shape_idx}" type="CollisionShape3D" parent="."]
"""
            if flip_y:
                # Apply the flip transform to the collision shape too so it matches the model's visual flip!
                nodes_tscn += 'transform = Transform3D(1, 0, 0, 0, -1, 8.74228e-08, 0, -8.74228e-08, -1, 0, 0, 0)\n'
            
            nodes_tscn += f'shape = SubResource("ConvexPolygonShape3D_{shape_idx}")\n'
            
            shape_idx += 1
            
    tscn += "\n" + nodes_tscn
    
    with open(f"Entities/{entity_name}.tscn", "w", encoding='utf-8') as f:
        f.write(tscn)
    print(f"Generated {entity_name}.tscn")

generate_tscn("BoomThing", "JamjamBoom.glb", "boom_thing.gd", False)
generate_tscn("Hanger", "Hanger.entity.glb", "hanger.gd", False)
generate_tscn("Skull", "JamjamHangingSkull.glb", "skull.gd", False)
