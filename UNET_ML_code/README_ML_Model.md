# CryoAerosol UNET-Attention

Segmenting spray droplets for the cryoaerosol spray. The network is a multi-output Attention U-Net: one head gives droplet centroids and the other marks the perimeter. This has been done to separate the overlapping droplets in the images. We have included the training data and the model in this repository.

```
Trained_Model/AttentionUNET_Multichannel.keras   # Keras 3.5 checkpoint (~448 MB)
Training_Dataset/X_train_600_896x896.npy         # 600 RGB images of size 896×896
Training_Dataset/Y_train_centroid_600_896x896.npy # 600 centeroid masks of size 896×896
Training_Dataset/Y_train_perimeter_600_896x896.npy # 600 perimeter masks of size 896×896
train.py                                         # training
predict.py                                       # run the model on a new image
requirements.txt
```

## 1. Dataset composition and availability

- Original microscopy frames (train / val / test): The orifinal microscopy images were of size 5440x3648, these images were chopped in to 15 images by cropping 1000x1000 (5 along horizontal and 3 along vertical) and then resized to 896x896 size for storing. This allows us to optimize the GPU RAM requirements for training and dsetection. We can including final training dataset instead of original frames. Training used **600** images with 896 × 896 patches.
- Training tiles: **480** (80% of 600)
- Validation tiles: **120** (20% of 600)
- Test tiles: none saved with the training arrays. New frames were only used at inference (1000 × 1000 crop, then resize to 896 × 896).
- Manually annotated droplets (ground truth in the 600 tiles): **8493** droplets
- Split: We first crop the large images into 1000 × 1000 tiles (then resized them to 896 × 896). After that we split the 600 tiles into training (80%) and validation (20%). 


---

## 2. Model details

- Architecture: multi-output **Attention U-Net** (`Attention_UNet_multi_channel`). U-Net encoder/decoder with attention gates on skip connections. Input 896 × 896 × 3; filters 64 → 128 → 256 → 512 → 1024; dropout 0.1; two sigmoid heads (`output2` centroids, `output3` perimeters).
- Framework: TensorFlow / Keras
- Python: ~3.10 (Colab default)
- Keras: 3.5.0
- TensorFlow: 2.x (`tensorflow>=2.17`)
- Other: numpy, opencv-python, scikit-image, tqdm
- Optimizer: Adam
- Learning rate: 0.001
- Epochs: 50 (early stopping on `val_loss`, patience 4)
- Batch size: 4
- Loss: binary cross-entropy on both centroid and the perimeter

---

## 3. Model availability

Trained weights are included:

`Trained_Model/AttentionUNET_Multichannel.keras`

```python
import numpy as np
import tensorflow as tf

model = tf.keras.models.load_model("Trained_Model/AttentionUNET_Multichannel.keras")
x = np.load("Training_Dataset/X_train_600_896x896.npy").astype("float32") / 255.0
centroid, perimeter = model.predict(x[:1], verbose=0)
```

---

## 4. Computational resources

- GPU: NVIDIA A100 (Google Colab, high-memory runtime)
- Training: A100
- Inference: A100 / GPU in Colab (`model.predict`)
- Approximate training time: 50 minutes

---

## 5. Reproducibility materials

`README_ML_Model.md` plus `requirements.txt`, `train.py`, and `predict.py`.

```bash
pip install -r requirements.txt
python train.py
python predict.py --image path/to/frame.tif
```

