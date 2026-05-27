allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directory safely
val rootBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(rootBuildDir)

subprojects {
    val subprojectName = name
    layout.buildDirectory.set(rootBuildDir.dir(subprojectName))
    
    // Use the afterEvaluate block to ensure compatibility is set after plugins are loaded
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_21.toString()
            targetCompatibility = JavaVersion.VERSION_21.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
