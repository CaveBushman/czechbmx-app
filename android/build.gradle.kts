allprojects {
    repositories {
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
    // Přeskočit :app — ten je už vyhodnocen výše, afterEvaluate by selhalo.
    // Pro ostatní pluginy (add_2_calendar apod.) přepíšeme starý compileSdk 33 → 36.
    if (project.name != "app") {
        afterEvaluate {
            (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)?.apply {
                if (compileSdkVersion == "android-33") compileSdkVersion(36)
            }
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
