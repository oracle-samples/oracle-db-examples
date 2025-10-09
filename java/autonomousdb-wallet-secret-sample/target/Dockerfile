FROM openjdk:11

RUN mkdir /app
COPY libs /app/libs
COPY adb-health-check.jar /app

# The driver will look for the wallet in folder /app/wallet
# This value must match the one in the mountPath of the container
# Reference in src/main/k8s/app.yaml 

CMD ["java", \ 
  "-Doracle.net.tns_admin=/app/wallet", \ 
  "-Doracle.net.wallet_location=/app/wallet", \ 
  "-Doracle.jdbc.fanEnabled=false", \
  "-jar", \
  "/app/adb-health-check.jar"]