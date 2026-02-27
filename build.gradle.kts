plugins {
    id("java")
    id("net.minecraftforge.gradle") version "6.0.+"
    id("org.spongepowered.mixin") version "0.7.+"
}

group = "me.jellysquid.mods"
version = "0.5.13-forge"

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(17))
}

minecraft {
    mappings("official", "1.20.1")

    accessTransformer(file("src/main/resources/META-INF/accesstransformer.cfg"))

    runs {
        create("client") {
            workingDirectory(project.file("run"))

            property("forge.logging.markers", "REGISTRIES")
            property("forge.logging.console.level", "debug")

            arg("--mixin.config=sodium.mixins.json")

            mods {
                create("sodium") {
                    source(sourceSets.main.get())
                }
            }
        }
    }
}

mixin {
    add(sourceSets.main.get(), "sodium.refmap.json")
    config("sodium.mixins.json")
}

repositories {
    maven {
        name = "Sponge"
        url = uri("https://repo.spongepowered.org/maven/")
    }
    mavenCentral()
}

dependencies {
    minecraft("net.minecraftforge:forge:1.20.1-47.4.10")

    annotationProcessor("org.spongepowered:mixin:0.8.5:processor")
}

// Merge former api and workarounds source sets into main
sourceSets {
    main {
        java {
            srcDirs("src/main/java", "src/api/java", "src/workarounds/java")
        }
        resources {
            srcDirs("src/main/resources")
        }
    }
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.release.set(17)
}

tasks.jar {
    manifest {
        attributes(
            "MixinConfigs" to "sodium.mixins.json"
        )
    }

    from("${rootProject.projectDir}/LICENSE.md")
}
