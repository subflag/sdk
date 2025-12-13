plugins {
    kotlin("jvm") version "1.9.22"
    application
}

group = "com.example"
version = "1.0.0"

repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

dependencies {
    // Subflag OpenFeature provider from JitPack
    implementation("com.github.subflag:sdk:sdk-kotlin-v0.5.0")
}

application {
    mainClass.set("com.example.MainKt")
}

kotlin {
    jvmToolchain(17)
}
