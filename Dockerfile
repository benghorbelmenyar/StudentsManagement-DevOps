FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/*.jar app.jar # Copier le JAR
EXPOSE 8090
ENTRYPOINT ["java", "-jar", "app.jar"] # Copier le JAR
