#!/bin/bash
#
# jmeter-ec2 - Install Script (Runs on remote ec2 server)
#

function install_jmeter_plugins() {
    echo "Installing plugins..."
    wget -q -O ~/JMeterPlugins-Extras.jar https://s3.amazonaws.com/jmeter-ec2/JMeterPlugins-Extras.jar
    wget -q -O ~/JMeterPlugins-Standard.jar https://s3.amazonaws.com/jmeter-ec2/JMeterPlugins-Standard.jar
    mv ~/JMeterPlugins*.jar ~/$JMETER_VERSION/lib/ext/
}

function install_java() {
    echo "Installing java 8..."
    sudo yum install java-1.8.0-openjdk -y
    echo "Removic java 7..."
    sudo yum remove java-1.7.0-openjdk -y
    echo "Java installed"
}

function install_jmeter() {
    # ------------------------------------------------
    #      Decide where to download jmeter from
    #
    # Order of preference:
    #   1. S3, if we have a copy of the file
    #   2. Mirror, if the desired version is current
    #   3. Archive, as a backup
    # ------------------------------------------------
    if [ $(curl -sI https://s3.amazonaws.com/jmeter-ec2/$JMETER_VERSION.tgz | grep -c "403 Forbidden") -eq "0" ] ; then
        # We have a copy on S3 so use that
        echo "Downloading jmeter from S3..."
        wget -q -O ~/$JMETER_VERSION.tgz https://s3.amazonaws.com/jmeter-ec2/$JMETER_VERSION.tgz
    elif [ $(echo $(curl -s 'http://www.apache.org/dist/jmeter/binaries/') | grep -c "$JMETER_VERSION") -gt "0" ] ; then
        # Nothing found on S3 but this is the current version of jmeter so use the preferred mirror to download
        echo "downloading jmeter from a Mirror..."
        wget -q -O ~/$JMETER_VERSION.tgz "http://www.apache.org/dyn/closer.cgi?filename=jmeter/binaries/$JMETER_VERSION.tgz&action=download"
    else
        # Fall back to the archive server
        echo "Downloading jmeter from Apache Archive..."
        wget -q -O ~/$JMETER_VERSION.tgz http://archive.apache.org/dist/jmeter/binaries/$JMETER_VERSION.tgz
    fi
    # Untar downloaded file
    echo "Unpacking jmeter..."
    tar -xf ~/$JMETER_VERSION.tgz
    # install jmeter-plugins [http://code.google.com/p/jmeter-plugins/]
    install_jmeter_plugins
    echo "Jmeter installed"
}

JMETER_VERSION=$1
cd ~

# Java
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
JAVA_VERSION_NORMALIZED=$(echo "$JAVA_VERSION" | awk -F. '{printf("%02d%02d",$1,$2);}')
if [[ "$JAVA_VERSION_NORMALIZED" < "0108" ]]; then
    echo "Java is not installed or version too old. Version: $JAVA_VERSION"
    install_java
else
    echo "Correct Java is already installed. Version: $JAVA_VERSION"
fi

# JMeter
if [ ! -d "$JMETER_VERSION" ] ; then
    # install jmeter
    install_jmeter
else
    echo "JMeter is already installed"
fi

# Done
echo "software installed"
