# Mantener clases de Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }

# Evitar que se obfusquen clases de Kotlin
-keep class kotlin.Metadata { *; }
