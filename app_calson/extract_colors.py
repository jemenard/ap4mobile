import sys
import struct
from collections import Counter

try:
    from PIL import Image
except ImportError:
    print("Pillow not installed")
    sys.exit(1)

def get_dominant_colors(image_path, num_colors=3):
    try:
        image = Image.open(image_path)
        image = image.convert('RGBA') # Handle transparency
        image = image.resize((100, 100))
        
        pixels = list(image.getdata())
        
        quantized_pixels = []
        for r, g, b, a in pixels:
             if a < 128: # Ignore transparent
                 continue
             quantized_pixels.append((r & 0xE0, g & 0xE0, b & 0xE0)) # Coarser quantization
             
        counts = Counter(quantized_pixels)
        most_common = counts.most_common(num_colors)
        
        print("Dominant Colors:")
        for color, count in most_common:
            r, g, b = color
            print(f"#{r:02x}{g:02x}{b:02x}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        get_dominant_colors(sys.argv[1])
    else:
        print("Usage: python extract_colors.py <image_path>")
