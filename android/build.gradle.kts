plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    buildDir = File(rootDir, "../build")
}

subprojects {
    buildDir = File(rootDir, "../build/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(buildDir)
}