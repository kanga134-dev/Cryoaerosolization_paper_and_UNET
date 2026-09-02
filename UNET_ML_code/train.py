# -*- coding: utf-8 -*-
"""
train.py  — 

We load 600 tiles (896 x 896) and train an Attention U-Net with two outputs:
  output2 = droplet centres
  output3 = droplet outlines

Run:  python train.py
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import models, layers
from tensorflow.keras import backend as K
from tensorflow.keras.utils import register_keras_serializable


# =============================================================================
# 1) Load the training tiles
# =============================================================================
# Run python train.py from the repo folder (after git clone and git lfs pull).
drive = 'Training_Dataset'

X_train = np.load(drive + '/' + 'X_train_600_896x896.npy')
Y_train_centroid = np.load(drive + '/' + 'Y_train_centroid_600_896x896.npy')
Y_train_perimeter = np.load(drive + '/' + 'Y_train_perimeter_600_896x896.npy')

print('Loaded X_train', X_train.shape)

seed = 42
np.random.seed = seed

IMG_WIDTH = 896
IMG_HEIGHT = 896
IMG_CHANNELS = 3


# =============================================================================
# 2) Small building blocks used by the Attention U-Net
# =============================================================================

# The attention map is 1 channel. We copy it so it matches the skip-connection
# depth, then we multiply.
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


def repeat_elem(tensor, rep):
    return RepeatElementsLayer(repnum=rep, axis=3)(tensor)


def conv_block(x, filter_size, size, dropout, batch_norm=False):
    """Two 3x3 convolutions + ReLU. Optional batch-norm and dropout."""
    conv = layers.Conv2D(size, (filter_size, filter_size), padding="same")(x)
    if batch_norm:
        conv = layers.BatchNormalization(axis=3)(conv)
    conv = layers.Activation("relu")(conv)

    conv = layers.Conv2D(size, (filter_size, filter_size), padding="same")(conv)
    if batch_norm:
        conv = layers.BatchNormalization(axis=3)(conv)
    conv = layers.Activation("relu")(conv)

    if dropout > 0:
        conv = layers.Dropout(dropout)(conv)
    return conv


def gating_signal(input, out_size, batch_norm=False):
    """1x1 conv on the decoder map so we can compare it with the encoder skip."""
    x = layers.Conv2D(out_size, (1, 1), padding='same')(input)
    if batch_norm:
        x = layers.BatchNormalization()(x)
    x = layers.Activation('relu')(x)
    return x


def attention_block(x, gating, inter_shape):
    """
    Attention gate.

    x      = skip from the encoder (fine detail)
    gating = map from the decoder (bigger picture)

    We build a 0–1 map and multiply it with x so the skip keeps droplet
    pixels and damps background.
    """
    shape_x = K.int_shape(x)
    shape_g = K.int_shape(gating)

    # Theta_x path  (downsample the skip)
    theta_x = layers.Conv2D(inter_shape, (2, 2), strides=(2, 2), padding='same')(x)
    shape_theta_x = K.int_shape(theta_x)

    # Phi_g path  (project the decoder map, then match size)
    phi_g = layers.Conv2D(inter_shape, (1, 1), padding='same')(gating)
    upsample_g = layers.Conv2DTranspose(
        inter_shape, (3, 3),
        strides=(
            shape_theta_x[1] // shape_g[1],
            shape_theta_x[2] // shape_g[2]
        ),
        padding='same'
    )(phi_g)

    # Combine, then sigmoid -> attention weights
    concat_xg = layers.add([upsample_g, theta_x])
    act_xg = layers.Activation('relu')(concat_xg)
    psi = layers.Conv2D(1, (1, 1), padding='same')(act_xg)
    sigmoid_xg = layers.Activation('sigmoid')(psi)
    shape_sigmoid = K.int_shape(sigmoid_xg)

    # Upsample the weights back to the skip size
    upsample_psi = layers.UpSampling2D(
        size=(
            shape_x[1] // shape_sigmoid[1],
            shape_x[2] // shape_sigmoid[2]
        )
    )(sigmoid_xg)

    upsample_psi = repeat_elem(upsample_psi, shape_x[3])
    y = layers.multiply([upsample_psi, x])

    result = layers.Conv2D(shape_x[3], (1, 1), padding='same')(y)
    result_bn = layers.BatchNormalization()(result)
    return result_bn


# =============================================================================
# UNET Architecture with two outputs-Centroid and Perimeter
# =============================================================================

def Attention_UNet(input_shape, dropout_rate=0.1, batch_norm=True):
    FILTER_NUM = 64     
    FILTER_SIZE = 3
    UP_SAMP_SIZE = 2

    inputs = tf.keras.Input(input_shape, dtype=tf.float32)

    # --- Encoder ---
    conv_128 = conv_block(inputs, FILTER_SIZE, FILTER_NUM, dropout_rate, batch_norm)
    pool_64 = tf.keras.layers.MaxPooling2D(pool_size=(2, 2))(conv_128)

    conv_64 = conv_block(pool_64, FILTER_SIZE, 2 * FILTER_NUM, dropout_rate, batch_norm)
    pool_32 = tf.keras.layers.MaxPooling2D(pool_size=(2, 2))(conv_64)

    conv_32 = conv_block(pool_32, FILTER_SIZE, 4 * FILTER_NUM, dropout_rate, batch_norm)
    pool_16 = tf.keras.layers.MaxPooling2D(pool_size=(2, 2))(conv_32)

    conv_16 = conv_block(pool_16, FILTER_SIZE, 8 * FILTER_NUM, dropout_rate, batch_norm)
    pool_8 = tf.keras.layers.MaxPooling2D(pool_size=(2, 2))(conv_16)

    conv_8 = conv_block(pool_8, FILTER_SIZE, 16 * FILTER_NUM, dropout_rate, batch_norm)

    # --- Decoder---
    gating_16 = gating_signal(conv_8, 8 * FILTER_NUM, batch_norm)
    att_16 = attention_block(conv_16, gating_16, 8 * FILTER_NUM)
    up_16 = tf.keras.layers.UpSampling2D(size=(UP_SAMP_SIZE, UP_SAMP_SIZE), data_format="channels_last")(conv_8)
    up_16 = tf.keras.layers.concatenate([up_16, att_16], axis=3)
    up_conv_16 = conv_block(up_16, FILTER_SIZE, 8 * FILTER_NUM, dropout_rate, batch_norm)

    gating_32 = gating_signal(up_conv_16, 4 * FILTER_NUM, batch_norm)
    att_32 = attention_block(conv_32, gating_32, 4 * FILTER_NUM)
    up_32 = tf.keras.layers.UpSampling2D(size=(UP_SAMP_SIZE, UP_SAMP_SIZE), data_format="channels_last")(up_conv_16)
    up_32 = tf.keras.layers.concatenate([up_32, att_32], axis=3)
    up_conv_32 = conv_block(up_32, FILTER_SIZE, 4 * FILTER_NUM, dropout_rate, batch_norm)

    gating_64 = gating_signal(up_conv_32, 2 * FILTER_NUM, batch_norm)
    att_64 = attention_block(conv_64, gating_64, 2 * FILTER_NUM)
    up_64 = tf.keras.layers.UpSampling2D(size=(UP_SAMP_SIZE, UP_SAMP_SIZE), data_format="channels_last")(up_conv_32)
    up_64 = tf.keras.layers.concatenate([up_64, att_64], axis=3)
    up_conv_64 = conv_block(up_64, FILTER_SIZE, 2 * FILTER_NUM, dropout_rate, batch_norm)

    gating_128 = gating_signal(up_conv_64, FILTER_NUM, batch_norm)
    att_128 = attention_block(conv_128, gating_128, FILTER_NUM)
    up_128 = tf.keras.layers.UpSampling2D(size=(UP_SAMP_SIZE, UP_SAMP_SIZE), data_format="channels_last")(up_conv_64)
    up_128 = tf.keras.layers.concatenate([up_128, att_128], axis=3)
    up_conv_128 = conv_block(up_128, FILTER_SIZE, FILTER_NUM, dropout_rate, batch_norm)

    # Shared 16-channel map, then two heads
    multi_feature = tf.keras.layers.Conv2D(16, (1, 1))(up_conv_128)
    multi_feature = tf.keras.layers.BatchNormalization(axis=3)(multi_feature)
    multi_feature = tf.keras.layers.Activation('relu')(multi_feature)

    output2 = tf.keras.layers.Conv2D(1, (1, 1), activation='sigmoid', name='output2')(multi_feature)  # centres
    output3 = tf.keras.layers.Conv2D(1, (1, 1), activation='sigmoid', name='output3')(multi_feature)  # perimeter

    model = tf.keras.Model(inputs, [output2, output3], name="Attention_UNet_multi_channel")
    model.compile(
        optimizer='adam',   
        loss={'output2': 'binary_crossentropy', 'output3': 'binary_crossentropy'},
        metrics={'output2': 'accuracy', 'output3': 'accuracy'}
    )
    return model


# =============================================================================
# 4) Build the model and train 
# =============================================================================
input_shape = (896, 896, 3)
model = Attention_UNet(input_shape, dropout_rate=0.1, batch_norm=True)
print(f"Trainable params: {model.count_params():,}")

checkpointer = tf.keras.callbacks.ModelCheckpoint('model.keras', verbose=1, save_best_only=True)

callbacks = [
    tf.keras.callbacks.EarlyStopping(patience=4, monitor='val_loss'),
    tf.keras.callbacks.TensorBoard(log_dir='logs'),
]

# 80% train / 20% val on the 600 images. Batch 4, up to 50 epochs.
results = model.fit(
    X_train,
    [Y_train_centroid, Y_train_perimeter],
    validation_split=0.2,
    batch_size=4,
    epochs=50,
    callbacks=callbacks,
)
