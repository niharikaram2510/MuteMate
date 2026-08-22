from keras.models import load_model

# Load your original model (.keras format)
model = load_model("signlang_v2_model.keras", compile=False)

# Save in older, compatible .h5 format
model.save("signlang_v2_model_compatible.h5")

print("✅ Model converted successfully! Saved as signlang_v2_model_compatible.h5")
