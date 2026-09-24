**MuteMate — Sign Language Translator**



**MuteMate** is an AI-powered Sign Language Translation application designed to help bridge communication between sign-language users and people who may not understand sign language.



The project uses \*\*computer vision, machine learning, and real-time hand/pose landmark detection\*\* to recognize sign language gestures and translate them into understandable text.







✨ **Features**



\* 🤟 Real-time sign language gesture recognition

\* 🎥 Live camera-based translation

\* 🧠 Machine learning-based gesture classification

\* 📹 Computer vision and hand landmark detection

\* 🔤 Support for multiple sign-language classes

\* 📚 Learning section for practicing signs

\* 🖥️ Web-based user interface

\* ⚡ Flask backend for model inference

\* 📱 Responsive frontend interface







🏗️ **Project Architecture**





&#x20;                   ┌─────────────────────┐

&#x20;                   │     User Camera     │

&#x20;                   └──────────┬──────────┘

&#x20;                              │

&#x20;                              ▼

&#x20;                   ┌─────────────────────┐

&#x20;                   │   Frontend (Flutter)│

&#x20;                   │    Live Translation │

&#x20;                   └──────────┬──────────┘

&#x20;                              │

&#x20;                              ▼

&#x20;                   ┌─────────────────────┐

&#x20;                   │   Flask Backend     │

&#x20;                   │   / Model Inference│

&#x20;                   └──────────┬──────────┘

&#x20;                              │

&#x20;                              ▼

&#x20;                   ┌─────────────────────┐

&#x20;                   │ Computer Vision /   │

&#x20;                   │ MediaPipe Landmarks │

&#x20;                   └──────────┬──────────┘

&#x20;                              │

&#x20;                              ▼

&#x20;                   ┌─────────────────────┐

&#x20;                   │ TensorFlow / Keras  │

&#x20;                   │ Classification Model│

&#x20;                   └──────────┬──────────┘

&#x20;                              │

&#x20;                              ▼

&#x20;                   ┌─────────────────────┐

&#x20;                   │ Recognized Sign /   │

&#x20;                   │ Translated Output   │

&#x20;                   └─────────────────────┘









📁 **Project Structure**





MuteMate/

│

├── backend/

│   ├── app.py

│   ├── signlang\_v2\_model.keras

│   ├── label\_classes.npy

│   └── ...

│

├── signlang\_fe/

│   ├── lib/

│   │   ├── home\_page.dart

│   │   ├── live\_translation\_page.dart

│   │   ├── learn\_page.dart

│   │   ├── loginpage.dart

│   │   ├── settings.dart

│   │   └── ...

│   │

│   └── ...

│

└── README.md



&#x20;🛠️ Tech Stack



&#x20;Frontend



Flutter

Dart

Flutter Web

Camera access for live translation



Backend



Python

Flask

Flask-CORS



AI / Machine Learning



TensorFlow

Keras

MediaPipe

OpenCV

NumPy



Model



The project uses a trained Keras classification model to classify extracted sign-language landmark features.







🧠 **Machine Learning Pipeline**



The translation pipeline follows these main steps:





Camera Input

&#x20;    ↓

Video Frame

&#x20;    ↓

Hand / Pose Landmark Detection

&#x20;    ↓

Landmark Feature Extraction

&#x20;    ↓

Feature Preprocessing

&#x20;    ↓

Trained ML Model

&#x20;    ↓

Sign Classification

&#x20;    ↓

Predicted Label

&#x20;    ↓

Translated Output





The model is trained using landmark-based features rather than directly classifying raw images. This reduces the dimensionality of the input and allows the model to focus on the spatial configuration of the gesture.







&#x20;📊 **Model Performance**



The trained model was evaluated using a holdout test dataset.



**Holdout Test Accuracy: 99.73%**



The dataset used for evaluation contained approximately 16,500 samples across 33 sign classes.



Note: Model accuracy on a test dataset does not necessarily represent real-world performance. Live camera performance can be affected by lighting, camera position, hand visibility, background conditions, and landmark-detection accuracy.





⚙️ **Backend Setup**



1\. Clone the repository





git clone https://github.com/niharikaram2510/MuteMate.git

cd MuteMate





2\. Create a virtual environment





python -m venv backend\_env





3\. Activate the environment



Windows:

backend\_env\\Scripts\\activate





Linux / macOS:





source backend\_env/bin/activate





4\. Install dependencies





pip install flask flask-cors tensorflow keras mediapipe opencv-python numpy



5\. Start the backend



Navigate to the backend directory:





cd backend





Then run:





python app.py





The Flask server will start and provide the API used by the frontend.





💻 Frontend Setup



Navigate to the Flutter frontend:





cd signlang\_fe





Install the required packages:





flutter pub get





Run the application:





flutter run





For Flutter Web:





flutter run -d chrome





When using live translation, allow the browser to access the camera.







&#x20;🎥 **Live Translation**



The Live Translation module captures frames from the user's camera and processes the detected gesture through the machine-learning pipeline.





Camera

&#x20; ↓

Live Frame

&#x20; ↓

MediaPipe

&#x20; ↓

Landmarks

&#x20; ↓

Feature Vector

&#x20; ↓

ML Model

&#x20; ↓

Predicted Sign





The predicted sign is then displayed through the application interface.







📚 **Learning Module**



MuteMate also includes a learning section that allows users to explore supported signs and practice recognizing them.



This makes the application useful not only as a translator but also as a basic learning aid for sign language.





🔮 **Future Improvements**



Potential improvements include:



\* Improve real-time landmark detection accuracy

\* Expand the number of supported signs

\* Support continuous sentence-level translation

\* Improve handling of different lighting and backgrounds

\* Add text-to-speech output

\* Add speech-to-text functionality

\* Improve recognition of dynamic signs

\* Add more robust error handling

\* Deploy the backend to a cloud service

\* Improve accessibility and mobile support







🎯 **Project Objective**



The primary objective of MuteMate is to develop an accessible technology solution that can assist communication between sign-language users and non-sign-language users.



By combining \*\*computer vision, machine learning, and an intuitive interface\*\*, the project aims to make sign-language translation more accessible in everyday situations.



👩‍💻 **Contributors**



Team MuteMate



Developed as an academic project using Flutter, Flask, TensorFlow, MediaPipe, and OpenCV.







📄 **License**



This project was developed for educational and academic purposes.



