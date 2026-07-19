import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("app")

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "com.example.temp_new.dev"
        }
        create("staging") {
            dimension = "app"
            applicationId = "com.example.temp_new.staging"
        }
        create("prod") {
            dimension = "app"
            applicationId = "com.example.temp_new"
        }
    }
}
