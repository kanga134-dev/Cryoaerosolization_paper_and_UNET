"""
predict.py

Run the trained model on one image, measure diameters, and mark
vitrified (pink) vs frozen (green)

  python predict.py --image microscope_image.tif
"""

import argparse
import os

import cv2
import numpy as np
import tensorflow as tf
from sklearn.cluster import DBSCAN
from tensorflow.keras import layers
from tensorflow.keras import backend as K
from tensorflow.keras.utils import register_keras_serializable


# Needed so Keras can load the saved Attention U-Net
@register_keras_serializable()
class RepeatElementsLayer(layers.Layer):
    def __init__(self, repnum, axis=3, **kwargs):
        super(RepeatElementsLayer, self).__init__(**kwargs)
        self.repnum = repnum
        self.axis = axis

    def call(self, inputs):
        return K.repeat_elements(inputs, self.repnum, axis=self.axis)

    def get_config(self):
        config = super(RepeatElementsLayer, self).get_config()
        config.update({'repnum': self.repnum, 'axis': self.axis})
        return config


# =============================================================================
# Parameters of the Image before feeding to the model
# =============================================================================
CHOP = 1000          # crop the image into 1000 x 1000 squares
TILE = 896           # resizing each square to 896 x 896 for the network
MODEL_FILE = os.path.join('Trained_Model', 'AttentionUNET_Multichannel.keras')

# Scale of the Microscope;
UM_PER_PX = (100.0 / 193.0) * (CHOP / TILE)

MIN_DIAMETER_UM = 85.0   
CENTROID_CUTOFF = 0.04 
EDGE_CUTOFF = 0.3

INTENSITY_THRESHOLD = 60 # if less than 60-vitrified else frozen
INTENSITY_RADIUS = 70 # Taking average of intensity values of all pixels inside this radius


def crop_image(image_path):
    """
    Crop the image in 1000-pixel steps.
    Resize each square to 896 x 896.
    """
    bgr = cv2.imread(image_path)
    if bgr is None:
        raise FileNotFoundError('Could not open: ' + image_path)

    photo = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    h, w = photo.shape[:2]
    tiles = []
    rows_cols = []

    tile_col = 0
    for x in range(0, w, CHOP):
        tile_row = 0
        for y in range(0, h, CHOP):
            if x + CHOP > w or y + CHOP > h:
                continue
            square = photo[y:y + CHOP, x:x + CHOP]
            small = cv2.resize(square, (TILE, TILE))
            tiles.append(small)
            rows_cols.append((tile_row, tile_col))
            tile_row += 1
        tile_col += 1

    return np.array(tiles, dtype=np.uint8), rows_cols


def stitch_tiles(tiles, rows_cols, maps):
    """Place the resized crop images back into one full-size image (plus centre/edge maps)."""
    n_rows = max(r for r, c in rows_cols) + 1
    n_cols = max(c for r, c in rows_cols) + 1
    H, W = n_rows * TILE, n_cols * TILE

    picture = np.zeros((H, W, 3), dtype=np.float32)
    centres = np.zeros((H, W), dtype=np.uint8)
    edges = np.zeros((H, W), dtype=np.uint8)

    for i, (tile_row, tile_col) in enumerate(rows_cols):
        y0, x0 = tile_row * TILE, tile_col * TILE
        picture[y0:y0 + TILE, x0:x0 + TILE] = tiles[i]
        centres[y0:y0 + TILE, x0:x0 + TILE] = maps[0][i, :, :, 0]
        edges[y0:y0 + TILE, x0:x0 + TILE] = maps[1][i, :, :, 0]

    return picture, centres, edges


def find_centres(centre_mask):
    """
    Centre predictions come out as grpup of pixels. Cluster them with DBSCAN and
    take the mean of each cluster as the droplet centre.
    """
    ys, xs = np.where(centre_mask > 0)
    if len(ys) == 0:
        return np.empty((0, 2))

    points = np.column_stack([ys, xs])
    labels = DBSCAN(eps=50, min_samples=500).fit_predict(points)

    droplets = []
    for lab in set(labels):
        if lab == -1:
            continue
        droplets.append(points[labels == lab].mean(axis=0))
    return np.array(droplets)


def diameter_from_rim(gray, x, y):
    """
    March outward from the centre until we hit the edge of the droplet.
    Diameter is twice the median radius (in stitched-image pixels).
    """
    h, w = gray.shape
    radii = []
    for ang in np.linspace(0, 2 * np.pi, 48, endpoint=False):
        dx, dy = np.cos(ang), np.sin(ang)
        dist, bright = [], []
        t = 0.0
        while t < 220:
            ix, iy = int(round(x + dx * t)), int(round(y + dy * t))
            if not (0 <= ix < w and 0 <= iy < h):
                break
            dist.append(t)
            bright.append(gray[iy, ix])
            t += 0.5
        if len(bright) < 30:
            continue
        dist, bright = np.array(dist), np.array(bright)
        smooth = np.convolve(bright, np.ones(9) / 9.0, mode='same')
        slope = np.gradient(smooth, dist)
        in_band = (dist >= 20) & (dist <= 160)
        if not np.any(in_band):
            continue
        slope_band = np.where(in_band, slope, 0.0)
        i = int(np.argmin(slope_band))
        if slope[i] >= -0.02:
            continue
        radii.append(dist[i])
    if len(radii) < 8:
        return None
    return 2.0 * float(np.median(radii))


def measure(picture, droplet_yx):
    gray = picture.mean(axis=2)
    out = []
    for y, x in droplet_yx:
        d_px = diameter_from_rim(gray, float(x), float(y))
        if d_px is None:
            continue
        d_um = d_px * UM_PER_PX
        if d_um < MIN_DIAMETER_UM:
            continue
        out.append((float(x), float(y), d_um, d_px))
    return out


def mean_brightness(picture, x, y, radius=INTENSITY_RADIUS):
    """Mean RGB inside a circle of given radius around (x, y)."""
    h, w = picture.shape[:2]
    x0, y0 = int(round(x)), int(round(y))
    x_min, x_max = max(x0 - radius, 0), min(x0 + radius + 1, w)
    y_min, y_max = max(y0 - radius, 0), min(y0 + radius + 1, h)
    xs = np.arange(x_min, x_max)
    ys = np.arange(y_min, y_max)
    X, Y = np.meshgrid(xs, ys)
    mask = (X - x0) ** 2 + (Y - y0) ** 2 < radius ** 2
    if not np.any(mask):
        return np.nan
    return float(np.mean(picture[Y[mask], X[mask], :]))


def classify_vitrified(picture, measured, threshold=INTENSITY_THRESHOLD):
    """Intensity classification
      mean brightness < threshold -> V (vitrified, pink)
      otherwise                   -> F (frozen, green)
    """
    rows = []
    d_v, d_f = [], []
    for x, y, d_um, d_px in measured:
        bright = mean_brightness(picture, x, y)
        if bright < threshold:
            label, color = 'V', (255, 20, 147)  # pink, RGB
            d_v.append(d_um)
        else:
            label, color = 'F', (0, 255, 0)     # green, RGB
            d_f.append(d_um)
        rows.append((x, y, d_um, d_px, bright, label, color))

    d_v, d_f = np.array(d_v), np.array(d_f)
    vol_v = np.sum(d_v ** 3) if d_v.size else 0.0
    vol_f = np.sum(d_f ** 3) if d_f.size else 0.0
    frac = vol_v / (vol_v + vol_f) if (vol_v + vol_f) > 0 else 0.0
    return rows, frac, len(d_v), len(d_f)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--image', required=True, help='path to the .tif or .png')
    p.add_argument('--model', default=MODEL_FILE)
    p.add_argument('--threshold', type=float, default=INTENSITY_THRESHOLD,
                   help='mean brightness cutoff (default 60): darker = vitrified')
    args = p.parse_args()

    print('1) Cropping image into tiles...')
    tiles, places = crop_image(args.image)
    print('   ', len(tiles), 'tiles of', TILE, 'x', TILE)

    print('2) Loading model and predicting...')
    model = tf.keras.models.load_model(
        args.model,
        custom_objects={'RepeatElementsLayer': RepeatElementsLayer},
    )
    centre_map, edge_map = model.predict(tiles, batch_size=2, verbose=1)
    centre_map = (centre_map > CENTROID_CUTOFF).astype(np.uint8)
    edge_map = (edge_map > EDGE_CUTOFF).astype(np.uint8)

    print('3) Stitching tiles back together...')
    picture, centres, edges = stitch_tiles(tiles, places, (centre_map, edge_map))

    print('4) Finding droplet centres...')
    droplets = find_centres(centres)
    print('   ', len(droplets), 'droplets')

    print('5) Measuring diameters...')
    measured = measure(picture, droplets)
    sizes = np.array([d_um for _, _, d_um, _ in measured])
    if sizes.size:
        print(
            '   n=%d  mean=%.2f um  median=%.2f um  min=%.2f  max=%.2f'
            % (sizes.size, sizes.mean(), np.median(sizes), sizes.min(), sizes.max())
        )
    else:
        print('   no droplets passed the size cutoff')
        return

    print('6) Labelling vitrified (pink) vs frozen (green)...')
    labelled, frac, n_v, n_f = classify_vitrified(picture, measured, args.threshold)
    print('   V = %d   F = %d   volume fraction vitrified = %.3f' % (n_v, n_f, frac))

    overlay = np.clip(picture, 0, 255).astype(np.uint8)
    for x, y, d_um, d_px, bright, label, color in labelled:
        cv2.circle(overlay, (int(x), int(y)), max(int(d_px / 2), 1), color, 8)
    cv2.imwrite('predicted_overlay.png', cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR))

    with open('predicted_diameters_um.csv', 'w') as f:
        f.write('x_px,y_px,diameter_um,mean_intensity,state\n')
        f.write('# V = vitrified (darker than %s), F = frozen/not vitrified\n' % args.threshold)
        f.write('# volume_fraction_vitrified=%.6f\n' % frac)
        for x, y, d_um, d_px, bright, label, color in labelled:
            f.write('%.2f,%.2f,%.4f,%.2f,%s\n' % (x, y, d_um, bright, label))

    print('Saved predicted_overlay.png (pink=V, green=F) and predicted_diameters_um.csv')


if __name__ == '__main__':
    main()
