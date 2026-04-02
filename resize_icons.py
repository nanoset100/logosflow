from PIL import Image
import sys

def resize_image(input_path, output_path, size=(512, 512)):
    try:
        with Image.open(input_path) as img:
            img = img.resize(size, Image.Resampling.LANCZOS)
            img.save(output_path, format="PNG")
            print(f"Resized {input_path} to {size} and saved to {output_path}")
    except Exception as e:
        print(f"Error processing {input_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # If paths are provided
        pass
    else:    
        resize_image(r"m:\MyProject777\logosflow\chimshin\assets\icons\app_icon.png", r"m:\MyProject777\logosflow\chimshin\assets\icons\app_icon_512.png")
        resize_image(r"m:\MyProject777\logosflow\wordbridge\assets\icons\app_icon.png", r"m:\MyProject777\logosflow\wordbridge\assets\icons\app_icon_512.png")
