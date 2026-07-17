# Flutter-specific ProGuard rules for Manbar Almasjid
# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Keep Gson/JSON models if used
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Suppress warnings for known missing classes in release builds
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
