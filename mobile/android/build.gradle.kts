plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

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
    
    fun applyNamespaceWorkaround(p: Project) {
        if (p.hasProperty("android")) {
            val android = p.extensions.getByName("android")
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(android) == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val defaultNamespace = if (p.group.toString().isNotEmpty()) {
                        p.group.toString()
                    } else {
                        "com.posify.${p.name.replace("-", "_")}"
                    }
                    setNamespace.invoke(android, defaultNamespace)
                }
            } catch (e: Exception) {}
        }
    }

    if (project.state.executed) {
        applyNamespaceWorkaround(project)
    } else {
        project.afterEvaluate { applyNamespaceWorkaround(project) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
