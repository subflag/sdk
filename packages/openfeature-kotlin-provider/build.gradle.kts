plugins {
    kotlin("jvm") version "1.9.22"
    `java-library`
    `maven-publish`
}

group = "com.subflag"
version = "0.3.0"

repositories {
    mavenCentral()
}

val ktorVersion = "2.3.7"

dependencies {
    // OpenFeature SDK
    api("dev.openfeature:sdk:1.7.0")

    // Ktor HTTP Client
    implementation("io.ktor:ktor-client-core:$ktorVersion")
    implementation("io.ktor:ktor-client-cio:$ktorVersion")
    implementation("io.ktor:ktor-client-content-negotiation:$ktorVersion")
    implementation("io.ktor:ktor-serialization-jackson:$ktorVersion")

    // Jackson Kotlin module for better Kotlin support
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:2.15.3")

    // Coroutines (for runBlocking in OpenFeature adapter)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // Testing
    testImplementation(kotlin("test"))
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("io.ktor:ktor-client-mock:$ktorVersion")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    withSourcesJar()
    withJavadocJar()
}

kotlin {
    jvmToolchain(17)
}

tasks.test {
    useJUnitPlatform()
}

// JitPack publishing - builds automatically from GitHub tags
// Coordinates: com.github.subflag.sdk:openfeature-kotlin-provider:TAG
publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["java"])
            groupId = "com.github.subflag.sdk"
            artifactId = "openfeature-kotlin-provider"
        }
    }
}
