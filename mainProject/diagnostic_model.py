import numpy as np
import json
from pathlib import Path
from PIL import Image
import tensorflow as tf
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input

def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=0)

# Paths
model_path = Path('prediction/model/shell_model4.tflite')
labels_path = Path('prediction/model/labels.json')

print("=" * 60)
print("SHELL MODEL INSPECTION")
print("=" * 60)

# Load model and labels
try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:
    from tensorflow.lite import Interpreter

interpreter = Interpreter(model_path=str(model_path))
interpreter.allocate_tensors()

with open(labels_path) as f:
    labels = json.load(f)

print(f"\nModel: {model_path}")
print(f"Model exists: {model_path.exists()}")
print(f"Model size: {model_path.stat().st_size / (1024*1024):.2f}MB")
print(f"\nLabels: {labels}")
print(f"Number of classes: {len(labels)}")

# Get model info
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\nInput details:")
for detail in input_details:
    print(f"  Shape: {detail['shape']}, Dtype: {detail['dtype']}")

print(f"\nOutput details:")
for detail in output_details:
    print(f"  Shape: {detail['shape']}, Dtype: {detail['dtype']}")

# Create a random test image and run inference
test_image = np.random.uniform(0, 255, (224, 224, 3)).astype(np.uint8)
print(f"\n--- Test with random image ---")
print(f"Random image shape: {test_image.shape}")

# Preprocess like the backend does
image_rgb = test_image  # already RGB
image_resized = tf.image.resize(image_rgb[np.newaxis], (224, 224))[0].numpy()
image_float = image_resized.astype(np.float32)
image_preprocessed = preprocess_input(image_float)
image_batch = np.expand_dims(image_preprocessed, axis=0)

print(f"Preprocessed shape: {image_batch.shape}")
print(f"Preprocessed range: [{image_batch.min():.4f}, {image_batch.max():.4f}]")

# Run inference
interpreter.set_tensor(input_details[0]['index'], image_batch.astype(np.float32))
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])

print(f"\nRaw output shape: {output.shape}")
print(f"Raw output dtype: {output.dtype}")
print(f"Raw output values: {output[0]}")
print(f"Output range: [{output.min():.6f}, {output.max():.6f}]")
print(f"Output sum: {output[0].sum():.6f}")

# Check if output looks like logits or probabilities
output_flat = output[0]
print(f"\nOutput interpretation:")
print(f"  Max value: {output_flat.max():.6f}")
print(f"  Min value: {output_flat.min():.6f}")
print(f"  Sum: {output_flat.sum():.6f}")

# Try softmax
softmax_output = softmax(output_flat)
print(f"\nAfter softmax:")
print(f"  Values: {softmax_output}")
print(f"  Max: {softmax_output.max():.6f}")
print(f"  Sum: {softmax_output.sum():.6f}")
print(f"  Top-1: {labels[np.argmax(softmax_output)]} ({softmax_output.max() * 100:.2f}%)")

# Also check without softmax (if already probabilities)
print(f"\nWithout softmax (assuming raw output):")
print(f"  Max: {output_flat.max():.6f}")
print(f"  Top-1: {labels[np.argmax(output_flat)]} ({output_flat.max() * 100:.2f}%)")

print("\n" + "=" * 60)
print("BACKEND MODEL INSPECTION")
print("=" * 60)

backend_model_path = Path('../backend/model/3class_model.tflite')
backend_labels_path = Path('../backend/model/labels.json')

if backend_model_path.exists():
    try:
        from ai_edge_litert.interpreter import Interpreter as BackendInterpreter
    except ImportError:
        from tensorflow.lite import Interpreter as BackendInterpreter
    
    backend_interpreter = BackendInterpreter(model_path=str(backend_model_path))
    backend_interpreter.allocate_tensors()
    
    with open(backend_labels_path) as f:
        backend_labels = json.load(f)
    
    print(f"\nModel: {backend_model_path}")
    print(f"Labels: {backend_labels}")
    print(f"Number of classes: {len(backend_labels)}")
    
    # Get model info
    backend_input_details = backend_interpreter.get_input_details()
    backend_output_details = backend_interpreter.get_output_details()
    
    print(f"\nInput details:")
    for detail in backend_input_details:
        print(f"  Shape: {detail['shape']}, Dtype: {detail['dtype']}")
    
    print(f"\nOutput details:")
    for detail in backend_output_details:
        print(f"  Shape: {detail['shape']}, Dtype: {detail['dtype']}")
    
    # Test with random image
    print(f"\n--- Test with random image ---")
    test_image = np.random.uniform(0, 255, (224, 224, 3)).astype(np.uint8)
    
    # Preprocess
    image_rgb = test_image
    image_resized = tf.image.resize(image_rgb[np.newaxis], (224, 224))[0].numpy()
    image_float = image_resized.astype(np.float32)
    image_preprocessed = preprocess_input(image_float)
    image_batch = np.expand_dims(image_preprocessed, axis=0)
    
    # Run inference
    backend_interpreter.set_tensor(backend_input_details[0]['index'], image_batch.astype(np.float32))
    backend_interpreter.invoke()
    backend_output = backend_interpreter.get_tensor(backend_output_details[0]['index'])
    
    print(f"\nRaw output shape: {backend_output.shape}")
    print(f"Raw output values: {backend_output[0]}")
    print(f"Output range: [{backend_output.min():.6f}, {backend_output.max():.6f}]")
    print(f"Output sum: {backend_output[0].sum():.6f}")
    
    # Try softmax
    backend_softmax = softmax(backend_output[0])
    print(f"\nAfter softmax:")
    print(f"  Values: {backend_softmax}")
    print(f"  Max: {backend_softmax.max():.6f}")
    print(f"  Top-1: {backend_labels[np.argmax(backend_softmax)]} ({backend_softmax.max() * 100:.2f}%)")
    
    # Without softmax
    print(f"\nWithout softmax:")
    print(f"  Max: {backend_output[0].max():.6f}")
    print(f"  Top-1: {backend_labels[np.argmax(backend_output[0])]} ({backend_output[0].max() * 100:.2f}%)")
else:
    print(f"Backend model not found at {backend_model_path}")
