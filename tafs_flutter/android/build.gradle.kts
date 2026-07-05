allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some older, unmaintained plugins (e.g. flutter_app_badger) don't declare an
// Android Gradle Plugin `namespace`, which AGP 8+ requires. Back-fill it from
// the plugin's own Gradle `group` (the long-standing convention these plugins
// already use in place of a namespace) so the build doesn't fail.
subprojects {
    val applyNamespaceFallback: () -> Unit = {
        val androidExtension = extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension && androidExtension.namespace == null) {
            androidExtension.namespace = group.toString()
        }
    }
    if (state.executed) {
        applyNamespaceFallback()
    } else {
        afterEvaluate { applyNamespaceFallback() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
