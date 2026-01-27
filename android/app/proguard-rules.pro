# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Kotlin
-keep class kotlin.Metadata { *; }

# Keep plugins safe
-keep class com.google.** { *; }
-dontwarn com.google.**

-keepattributes *Annotation*
