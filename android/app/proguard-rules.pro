# ML Kit text recognition keep rules
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Optional: Jika pakai GPU delegate dari TFLite
-keep class org.tensorflow.lite.** { *; }
