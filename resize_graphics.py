from PIL import Image
import sys

def resize_image(input_path, output_path, size=(1024, 500)):
    try:
        with Image.open(input_path) as img:
            # Crop to aspect ratio if necessary before resizing
            # generated images are likely 1024x1024 or similar, so cropping the middle
            target_ratio = size[0] / size[1]
            img_ratio = img.width / img.height
            
            if img_ratio > target_ratio:
                # Image is too wide
                new_width = int(target_ratio * img.height)
                offset = (img.width - new_width) / 2
                crop_box = (offset, 0, img.width - offset, img.height)
            else:
                # Image is too tall
                new_height = int(img.width / target_ratio)
                offset = (img.height - new_height) / 2
                crop_box = (0, offset, img.width, img.height - offset)
                
            img_cropped = img.crop(crop_box)
            img_resized = img_cropped.resize(size, Image.Resampling.LANCZOS)
            img_resized.save(output_path, format="PNG")
            print(f"Resized {input_path} to {size} and saved to {output_path}")
    except Exception as e:
        print(f"Error processing {input_path}: {e}")

if __name__ == "__main__":
    resize_image(r"C:\Users\nanos\.gemini\antigravity\brain\3db2c6fb-858a-4408-bd24-e65923360371\chimshin_feature_graphic_raw_1773276114617.png", r"m:\MyProject777\logosflow\chimshin\assets\icons\feature_graphic_1024x500.png")
    resize_image(r"C:\Users\nanos\.gemini\antigravity\brain\3db2c6fb-858a-4408-bd24-e65923360371\wordbridge_feature_graphic_raw_1773276134370.png", r"m:\MyProject777\logosflow\wordbridge\assets\icons\feature_graphic_1024x500.png")
