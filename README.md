# README: Howto

In this demo I’m going to provide a development pipeline (CI/CD) to a developer team from an organizational security perspective. Such pipeline needs to be published by an administrator first before it can be consumed by a developer or team of developers. This two step approach ensures compliance with organizational security regulations, as the Dev Team has no administrative access to these and therefore cannot change them.

Prerequisites:

I use Terraform to publish a GitHub repository including a protected GitHub Actions workflow file.

I assume the dev team to start a development cycle from scratch. To showcase the entire workflow a clone of the petclinic code base is being used.

## Step 1 Deploying/publishing the Pipeline

```bash
WORKDIR=$(pwd)
git clone https://github.com/joestack/jf-pipeline
cd jf-pipeline
```

Three variables are required to run the Terraform code.

**github_token**: used to authorize Terraform to perform actions on your GitHub account

**jf_url**: The URL of your JFrog organization

**jf_access_token**: A JFrog access token to authorize GitHub Actions

**repo**: optional (default is set to “jf-petclinic-demo”)

```bash
terraform init
terraform plan
terraform apply
```

## Step 2: Consuming the Pipeline

Preparing the code base:

```bash
cd $WORKDIR
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic

```

Cloning the Pipeline:

```bash
cd $WORKDIR
git clone https://github.com/joestack/jf-petclinic-demo
cd jf-petclinic-demo
cp -r ../spring-petclinic/* .
mvn -N wrapper:wrapper
sed -i 's|http://www.apache.org|https://www.apache.org|g' mvnw mvnw.cmd .mvn/wrapper/maven-wrapper.properties
```

Adding a Dockerfile to the code base:

```bash
FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline
COPY src ./src
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:17-jre-jammy
COPY --from=builder /app/target/*.jar /app/spring-petclinic.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/spring-petclinic.jar"]
```

Pushing the code to trigger the pipeline:

```bash
git add -A
git commit -m "run pipeline, run..."
git push
```

The status of the pipeline run can be reviewed on GitHub. Once successfully finished the newly generated Docker image can be pulled from Artifactory. 

```bash
jf docker pull [artifactory-url]/[repository-name]/[image-name]:[tag]
jf docker pull trial3i8n2w.jfrog.io/testpet-docker/jfrog-docker-petclinic-image:3
```

Finally run the image

```bash
docker run -d -p 8080:8080 trial3i8n2w.jfrog.io/testpet-docker/jfrog-docker-petclinic-image:3
```

and go to the URL "localhost:8080"
