from ai_vision import PersonDetector
import cv2

# Initialize once
ai = PersonDetector(focal_length=600)

# Inside your main loop
def main_loop():
    # ... your existing gadget code ...
    
    # Get image from your camera
    frame = camera.get_image() 
    
    # Run detection
    display_frame, data = ai.process_frame(frame)
    
    # Logic based on distance
    if len(data) > 0:
        closest_person = min(data, key=lambda x: x['distance'])
        print(f"Closest target is {closest_person['distance']}cm away")