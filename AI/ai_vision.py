import cv2
import math
from ultralytics import YOLO

class PersonDetector:
    def __init__(self, focal_length):
        # Load the lightweight YOLO model (Nano version for speed)
        # It will auto-download 'yolov8n.pt' the first time you run it.
        self.model = YOLO('yolov8n.pt')
        
        # Constants
        self.KNOWN_HEIGHT = 170.0  # Average human height in cm
        self.FOCAL_LENGTH = focal_length
        self.CONFIDENCE_THRESHOLD = 0.5
        self.CLASS_NAME = "person"

    def calculate_distance(self, pixel_height):
        """
        Distance = (Known Width * Focal Length) / Pixel Width
        """
        if pixel_height == 0: return 0
        return (self.KNOWN_HEIGHT * self.FOCAL_LENGTH) / pixel_height

    def process_frame(self, frame):
        """
        Takes an image frame, detects people, returns list of people 
        with their distance, and the annotated image.
        """
        # Run AI inference
        results = self.model(frame, verbose=False, classes=[0]) # classes=[0] detects only people
        
        detections = [] # To store list of found people: [{'id': 1, 'distance': 150}, ...]

        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Get bounding box coordinates
                x1, y1, x2, y2 = box.xyxy[0]
                x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
                
                # Calculate height of the bounding box in pixels
                pixel_height = y2 - y1
                
                # Calculate Distance
                distance_cm = self.calculate_distance(pixel_height)
                
                # Store data
                detections.append({
                    "bbox": (x1, y1, x2, y2),
                    "distance": distance_cm
                })

                # --- VISUALIZATION (Draw on frame) ---
                # Draw box
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
                # Draw text
                label = f"Person: {int(distance_cm)}cm"
                cv2.putText(frame, label, (x1, y1 - 10), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

        return frame, detections

# ==========================================
# EXAMPLE USAGE (How to run it)
# ==========================================
if __name__ == "__main__":
    # 1. SETUP: Replace 600 with the value you calculated in Phase 3
    my_focal_length = 600 
    detector = PersonDetector(focal_length=my_focal_length)

    # 2. OPEN CAMERA
    cap = cv2.VideoCapture(0) # 0 is usually the default webcam

    while True:
        ret, frame = cap.read()
        if not ret: break

        # 3. RUN AI ON THE FRAME
        processed_frame, people_data = detector.process_frame(frame)

        # 4. USE THE DATA
        for person in people_data:
            if person['distance'] < 100:
                print("ALERT: Person is too close!")

        # Show result
        cv2.imshow('AI Gadget Vision', processed_frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()