FROM jenkins/jenkins:lts-jdk21

# Skip setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xmx2g"
ENV JENKINS_OPTS="--httpPort=8080"
ENV CASC_JENKINS_CONFIG="/var/jenkins_home/casc.yaml"

# Install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy JCasC config
COPY jenkins.yaml /usr/share/jenkins/ref/casc.yaml
