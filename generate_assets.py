import os
import random
from PIL import Image, ImageDraw, ImageFont

def generate_lidar_bg(draw, width, height, num_dots=2000):
    for _ in range(num_dots):
        x = random.randint(0, width)
        y = random.randint(0, height)
        # Randomly choose between red and white, mostly red
        color = (255, 0, 0) if random.random() < 0.7 else (255, 255, 255)
        
        # Add some structure: more dots horizontally centered
        if random.random() < 0.5:
            x = int(random.gauss(width/2, width/4))
            x = max(0, min(width-1, x))
            
        r = random.randint(1, 3)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color)

def draw_text_glitch(draw, text, font, x, y, main_color, offset_x=3, offset_y=3):
    # Shadow/Glitch Red
    draw.text((x + offset_x, y + offset_y), text, font=font, fill=(255, 0, 0), anchor="mm")
    # Shadow/Glitch Black
    draw.text((x - offset_x, y - offset_y), text, font=font, fill=(0, 0, 0), anchor="mm")
    # Main White
    draw.text((x, y), text, font=font, fill=main_color, anchor="mm")

def create_icon():
    width, height = 512, 512
    img = Image.new('RGB', (width, height), color=(0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("Assets/Fonts/VCR_OSD_MONO_1.001.ttf", 350)
    except:
        font = ImageFont.load_default()
        
    # Just the letter 'L' for a clear silhouette at small sizes
    draw_text_glitch(draw, "L", font, width/2 + 20, height/2 - 20, (255, 255, 255), 8, 8)
    
    img.save("icon.png")
    print("Created icon.png")

def create_banner():
    width, height = 1024, 500
    img = Image.new('RGB', (width, height), color=(0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    generate_lidar_bg(draw, width, height, num_dots=3000)
    
    try:
        font = ImageFont.truetype("Assets/Fonts/VCR_OSD_MONO_1.001.ttf", 140)
    except:
        font = ImageFont.load_default()
        
    draw_text_glitch(draw, "L I D A R", font, width/2, height/2, (255, 255, 255), 5, 5)
    
    # Subtitle
    try:
        sub_font = ImageFont.truetype("Assets/Fonts/VCR_OSD_MONO_1.001.ttf", 40)
        draw.text((width/2, height/2 + 100), "NO WAY OUT", font=sub_font, fill=(255, 0, 0), anchor="mm")
    except:
        pass
        
    img.save("Assets/banner.png")
    print("Created Assets/banner.png")

if __name__ == "__main__":
    os.makedirs("Assets", exist_ok=True)
    create_icon()
    create_banner()
