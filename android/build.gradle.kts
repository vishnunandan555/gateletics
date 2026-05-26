allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(rootBuildDir)

subprojects {
    project.layout.buildDirectory.set(rootBuildDir.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withType<JavaPlugin> {
        extensions.configure<JavaPluginExtension> {
            toolchain {
                languageVersion.set(JavaLanguageVersion.of(21))
            }
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "21"
        targetCompatibility = "21"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
