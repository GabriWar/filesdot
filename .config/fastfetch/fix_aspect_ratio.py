#!/usr/bin/env python3

import os
import sys
from PIL import Image
import glob

def get_aspect_ratio(image_path):
    """Get the aspect ratio of an image"""
    try:
        with Image.open(image_path) as img:
            width, height = img.size
            return width / height
    except Exception as e:
        print(f"Error processing {image_path}: {str(e)}")
        return None

def resize_image(image_path, target_ratio, output_path=None):
    """Resize an image to match the target aspect ratio by stretching"""
    if output_path is None:
        output_path = image_path
    
    try:
        with Image.open(image_path) as img:
            width, height = img.size
            current_ratio = width / height
            
            # Check if the image already has the correct aspect ratio (with a small tolerance)
            tolerance = 0.01  # 1% tolerance
            if abs(current_ratio - target_ratio) / target_ratio < tolerance:
                print(f"Skipping {image_path} as it already has the correct aspect ratio ({current_ratio:.4f})")
                return True
            
            # Calculate new dimensions to match target ratio
            if current_ratio > target_ratio:
                # Image is too wide, keep the width and increase height
                new_width = width
                new_height = int(width / target_ratio)
            else:
                # Image is too tall, keep the height and increase width
                new_height = height
                new_width = int(height * target_ratio)
            
            # Resize the image by stretching it to the new dimensions
            new_img = img.resize((new_width, new_height), Image.LANCZOS)
            
            # Save the result
            new_img.save(output_path)
            print(f"Resized {image_path} from {width}x{height} to {new_width}x{new_height}")
            return True
            
    except Exception as e:
        print(f"Error resizing {image_path}: {str(e)}")
        return False

def main():
    logos_dir = os.path.join(os.path.expanduser("~"), ".config/fastfetch/logos")
    
    # Check if logos directory exists
    if not os.path.exists(logos_dir):
        print(f"Logos directory not found: {logos_dir}")
        sys.exit(1)
    
    # Get reference logo path
    reference_logo = os.path.join(logos_dir, "logo.png")
    
    if not os.path.exists(reference_logo):
        print(f"Reference logo not found: {reference_logo}")
        print("Please provide a reference logo named 'logo.png' in the logos directory")
        sys.exit(1)
    
    # Get reference aspect ratio
    reference_ratio = get_aspect_ratio(reference_logo)
    if reference_ratio is None:
        print("Could not determine aspect ratio of reference logo")
        sys.exit(1)
    
    print(f"Reference aspect ratio: {reference_ratio:.4f}")
    
    # Find all image files in the logos directory
    image_files = []
    for ext in ['*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp']:
        image_files.extend(glob.glob(os.path.join(logos_dir, ext)))
    
    # Exclude the reference logo from processing
    if reference_logo in image_files:
        image_files.remove(reference_logo)
    
    # Process each image
    processed_count = 0
    for image_path in image_files:
        print(f"Processing {image_path}...")
        if resize_image(image_path, reference_ratio):
            processed_count += 1
    
    print(f"Finished processing {processed_count} out of {len(image_files)} images")

if __name__ == "__main__":
    main()