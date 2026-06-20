import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    val project = this
    if (project.name != "app") {
        val configureAndroid = {
            project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(34)
            }
        }
        if (project.state.executed) {
            configureAndroid()
        } else {
            project.afterEvaluate {
                configureAndroid()
            }
        }
    }
    
    // Enforce Kotlin language version >= 1.8 to prevent deprecated 1.6 errors in libraries (like sentry_flutter)
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
