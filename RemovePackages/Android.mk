LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := RemovePackages
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES := \
    AmbientSensePrebuilt \
    arcore \
    Camera2 \
    DevicePolicyPrebuilt \
    Drive \
    FM2 \
    GoogleCamera \
    MaestroPrebuilt \
    Maps \
    MyVerizonServices \
    MicropaperPrebuilt \
    NgaResources \
    NovaBugreportWrapper \
    OBDM_Permissions \
    obdm_stub \
    OemDmTrigger \
    OPScreenRecord \
    Ornament \
    PrebuiltGoogleTelemetryTvp \
    SafetyHubPrebuilt \
    ScribePrebuilt \
    Showcase \
    Snap \
    SoundAmplifierPrebuilt \
    SprintDM \
    SprintHM \
    talkback \
    VZWAPNLib \
    VzwOmaTrigger \
    YouTube \
    YouTubeMusicPrebuilt

LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)
