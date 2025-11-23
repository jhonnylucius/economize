# ================================
# REGRAS PROGUARD - ECONOMIZE APP
# ================================

# GOOGLE PLAY CORE - CRITICO para deferred components e split install
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# FLUTTER - Manter classes essenciais do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# SQFLITE - Banco de dados local
-keep class com.tekartik.sqflite.** { *; }

# SHARED PREFERENCES
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# PATH PROVIDER
-keep class io.flutter.plugins.pathprovider.** { *; }

# SHARE PLUS
-keep class dev.fluttercommunity.plus.share.** { *; }

# URL LAUNCHER
-keep class io.flutter.plugins.urllauncher.** { *; }

# PERMISSION HANDLER
-keep class com.baseflow.permissionhandler.** { *; }

# FLUTTER LOCAL NOTIFICATIONS
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# PDF
-keep class printing.** { *; }

# SCREENSHOT
-keep class com.flutter.screenshot.** { *; }

# FL_CHART
-keep class com.github.aachartmodel.aainfographics.** { *; }

# ================================
# KOTLIN - Manter reflection
# ================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ================================
# ANDROID X - Compatibilidade
# ================================
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ================================
# GSON (se usado) - Serializacao
# ================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ================================
# REFLECTION - Manter anotacoes
# ================================
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ================================
# NATIVE METHODS - Nao ofuscar JNI
# ================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ================================
# ENUMS - Manter integridade
# ================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ================================
# PARCELABLE - Android IPC
# ================================
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ================================
# SERIALIZABLE - Java serialization
# ================================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ================================
# R8 OPTIMIZATIONS - Compatibilidade 16KB
# ================================
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# ================================
# WARNINGS - Suprimir avisos conhecidos
# ================================
-dontwarn com.google.android.gms.**
-dontwarn com.google.common.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
