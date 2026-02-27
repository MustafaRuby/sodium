pluginManagement {
    repositories {
        maven {
            name = "Forge"
            url = uri("https://maven.minecraftforge.net/")
        }
        maven {
            name = "Sponge"
            url = uri("https://repo.spongepowered.org/maven/")
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "sodium-forge"
