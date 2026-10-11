val flutterStorageBase =
    System.getenv("FLUTTER_STORAGE_BASE_URL")?.trimEnd('/') ?: "https://storage.googleapis.com"

allprojects {
    repositories {
        maven(url = "$flutterStorageBase/download.flutter.io") {
            content { includeGroup("io.flutter") }
        }
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/central")
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 9 validates compileSdk across library dependencies. Older plugins such as
// file_picker use API 34 while flutter_plugin_android_lifecycle requires API 36.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl {
                if ((it.compileSdk ?: 0) < 36) {
                    it.compileSdk = 36
                }
            }
        }
    }
}

subprojects {
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
