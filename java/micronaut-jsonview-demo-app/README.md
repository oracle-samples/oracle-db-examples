# Using JSON Relational Duality Views with Micronaut® Framework

This [blog](https://blogs.oracle.com/java/post/json-relational-duality-views-with-micronaut-framework) explains how to use the Oracle JSON Relational Duality feature in a Micronaut Java application.

This is an example application for Micronaut Data using an Oracle JSON Duality View.

It uses a test container with the container image "gvenzl/oracle-free:latest-faststart" by default and then
the datasource configuration is taken from the container before starting Micronaut application context. 

>Note: To run the application you need a Docker-API compatible container runtime such as [Docker](https://www.docker.io/gettingstarted/), [Podman](https://podman.io/docs/installation), or [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/) installed and running.

To get started, run the application as follows:

```
./gradlew run
```

Wait until the application has started and created the database schema.

Test the application by using curl to call the API.

1. List all the students and their schedules:

    ```bash
    curl http://localhost:8080/students
    ```

2. Retrieve a schedule by student name:

    ```bash
    curl http://localhost:8080/students/student/Jill
    ```

3. Retrieve a schedule by student id:

    ```bash
    curl http://localhost:8080/students/3
    ```

4. Create a new student with courses (and view that student's schedule):

    ```bash
    curl -d '{"student":"Sandro", "averageGrade":8.9, "courses": ["Math", "English"]}' \
    -H "Content-Type: application/json" \
    -X POST http://localhost:8080/students
    ```

5. Update a student's average grade (by student id):

    ```bash
    curl -X PUT http://localhost:8080/students/1/average_grade/9.8
    ```
    
6. Retrieve the maximum average grade:

    ```bash
    curl http://localhost:8080/students/max_average_grade
    ```

7. Update a student's name (by student id), for example, to correct a typo:
 
    ```bash
    curl -X PUT http://localhost:8080/students/1/student/Dennis
    ```

8. Delete a student by student id and retrieve the new maximum average grade (to confirm deletion):

    ```bash
    curl -X DELETE http://localhost:8080/students/1
    curl http://localhost:8080/students/max_average_grade
    ```
