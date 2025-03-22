#!/bin/bash
# Script to apply Java 23 changes to exchange-core

# Step 1: Create backup of original files
echo "Creating backups of original files..."
cp pom.xml pom.xml.backup
mkdir -p backups/src/main/java/exchange/core2/core/common/cmd
mkdir -p backups/src/main/java/exchange/core2/core
mkdir -p backups/src/main/java/exchange/core2/core/common
mkdir -p backups/src/main/java/exchange/core2/core/common/api/reports

cp src/main/java/exchange/core2/core/common/cmd/OrderCommand.java backups/src/main/java/exchange/core2/core/common/cmd/
cp src/main/java/exchange/core2/core/ExchangeCore.java backups/src/main/java/exchange/core2/core/
cp src/main/java/exchange/core2/core/common/MatcherTradeEvent.java backups/src/main/java/exchange/core2/core/common/
cp src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java backups/src/main/java/exchange/core2/core/common/api/reports/

# Step 2: Apply Java 23 pom.xml
echo "Applying Java 23 pom.xml..."
cp pom.xml.java23 pom.xml

# Step 3: Apply refactored Java files
echo "Applying refactored Java files..."
cp src/main/java/exchange/core2/core/common/cmd/OrderCommand.java.java23 src/main/java/exchange/core2/core/common/cmd/OrderCommand.java
cp src/main/java/exchange/core2/core/ExchangeCore.java.java23 src/main/java/exchange/core2/core/ExchangeCore.java
cp src/main/java/exchange/core2/core/common/MatcherTradeEvent.java.java23 src/main/java/exchange/core2/core/common/MatcherTradeEvent.java
cp src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java.java23 src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java

# Step 4: Compile the code
echo "Compiling the code..."
mvn clean compile

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful!"
else
    echo "Compilation failed. Restoring original files..."
    cp pom.xml.backup pom.xml
    cp backups/src/main/java/exchange/core2/core/common/cmd/OrderCommand.java src/main/java/exchange/core2/core/common/cmd/
    cp backups/src/main/java/exchange/core2/core/ExchangeCore.java src/main/java/exchange/core2/core/
    cp backups/src/main/java/exchange/core2/core/common/MatcherTradeEvent.java src/main/java/exchange/core2/core/common/
    cp backups/src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java src/main/java/exchange/core2/core/common/api/reports/
    echo "Original files restored."
fi
