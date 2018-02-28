LOCAL_PATH:= $(call my-dir)/..
include $(CLEAR_VARS)

LOCAL_MODULE     := duktape_android
LOCAL_CFLAGS     := -O3
LOCAL_SRC_FILES  := src/duktape.c
  
include $(BUILD_STATIC_LIBRARY)