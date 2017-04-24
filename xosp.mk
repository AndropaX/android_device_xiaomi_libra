# Boot animation
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080

# Inherit 64-bit configs
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common XOSP stuff.
$(call inherit-product, vendor/xosp/config/common_full_phone.mk)
$(call inherit-product, vendor/xosp/config/xosp.mk)

# Inherit device configuration
$(call inherit-product, device/xiaomi/libra/device.mk)

## Device identifier. This must come after all inclusions
PRODUCT_NAME := xosp_libra
PRODUCT_DEVICE := libra

BOARD_VENDOR := Xiaomi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Mi-4c
PRODUCT_MANUFACTURER := Xiaomi
TARGET_VENDOR := Xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME="libra" \
    BUILD_FINGERPRINT="Xiaomi/libra/libra:7.0/NRD90M/V8.2.3.0.NXKCNEC:user/release-keys" \
    PRIVATE_BUILD_DESC="libra-user 7.0 NRD90M V8.2.3.0.NXKCNEC release-keys"

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

IS_ARM64 := TRUE
ROOT_METHOD := magisk
    
