import cv2
from ultralytics import YOLO

# ================= CONFIGURATION =================
# 1. How close (in cm) must a person be to trigger "TURN ON"?
TRIGGER_DISTANCE = 200  

# 2. Camera Focal Length (Adjust this if distance numbers seem wrong)
# Increase if it says you are too close, Decrease if it says you are too far.
FOCAL_LENGTH = 600      

# 3. Real height of a person (Average 170cm)
REAL_HEIGHT = 170       
# =================================================

# Load the AI model (downloads automatically on first run)
print("Loading AI Model...")
model = YOLO('yolov8n.pt')

# Start Webcam
cap = cv2.VideoCapture(0)
cap.set(3, 1280) # Width
cap.set(4, 720)  # Height

def calculate_distance(pixel_height):
    if pixel_height == 0: return 0
    # Math: (Real Height * Focal Length) / Pixel Height
    return (REAL_HEIGHT * FOCAL_LENGTH) / pixel_height

print("Starting Camera...")

while True:
    ret, frame = cap.read()
    if not ret: break

    # Run AI - Detect only class 0 (Person)
    results = model(frame, verbose=False, classes=[0], conf=0.3)

    # Variables for logic
    person_nearby = False
    closest_distance = 9999

    # Process detections
    for result in results:
        for box in result.boxes:
            # Get coordinates
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            
            # Calculate height and distance
            pixel_height = y2 - y1
            dist = calculate_distance(pixel_height)
            
            # Track the closest person
            if dist < closest_distance:
                closest_distance = dist

            # Check if this specific person is close enough
            if dist < TRIGGER_DISTANCE:
                person_nearby = True

            # --- DRAW VISUALS ON PERSON ---
            color = (0, 255, 0) if dist < TRIGGER_DISTANCE else (0, 0, 255)
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.putText(frame, f"{int(dist)}cm", (x1, y1 - 10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

    # ================= UI STATUS INDICATOR =================
    if person_nearby:
        # Green Status Bar
        status_text = f"ACTION: TURN ON (Dist: {int(closest_distance)}cm)"
        bg_color = (0, 255, 0) # Green
        txt_color = (0, 0, 0)  # Black text
    else:
        # Red Status Bar
        status_text = "ACTION: TURN OFF (No one near)"
        bg_color = (0, 0, 255) # Red
        txt_color = (255, 255, 255) # White text

    # Draw the status bar at the top
    cv2.rectangle(frame, (0, 0), (1280, 60), bg_color, -1)
    cv2.putText(frame, status_text, (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 1, txt_color, 2)
    # =======================================================

    cv2.imshow('Gadget Logic Test', frame)

    # Press 'q' to quit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()