import os
from PIL import Image

def resize_screenshots(directory, target_size=(1080, 1920)):
    try:
        if not os.path.exists(directory):
            print(f"Directory not found: {directory}")
            return
            
        for filename in os.listdir(directory):
            if filename.lower().endswith((".jpg", ".jpeg", ".png")):
                # Skip already resized files just in case
                if "_1080x1920" in filename:
                    continue
                    
                input_path = os.path.join(directory, filename)
                
                # Create output filename
                name, ext = os.path.splitext(filename)
                output_filename = f"{name}_1080x1920{ext}"
                output_path = os.path.join(directory, output_filename)
                
                with Image.open(input_path) as img:
                    # Resize keeping aspect ratio by cropping or padding if needed.
                    # Given they are screenshots, simple resize is usually fine, but LANCZOS is high quality.
                    img_resized = img.resize(target_size, Image.Resampling.LANCZOS)
                    # For JPEGs, we should preserve RGB mode
                    if img_resized.mode == 'RGBA' and ext.lower() in ('.jpg', '.jpeg'):
                        img_resized = img_resized.convert('RGB')
                    img_resized.save(output_path)
                    print(f"Resized {filename} to {target_size} and saved as {output_filename}")
                    
    except Exception as e:
        print(f"Error processing: {e}")

if __name__ == "__main__":
    target_dir = r"m:\MyProject777\logosflow\chimshin\assets\images"
    resize_screenshots(target_dir)
