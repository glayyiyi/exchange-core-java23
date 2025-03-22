# Java 23 Migration Steps

This document outlines the step-by-step process for migrating the exchange-core project from Java 8 to Java 23.

## Phase 1: Environment Setup

### 1. Install Java 23
```bash
# For macOS with Homebrew
brew install openjdk@23

# For Ubuntu/Debian
sudo apt-get install openjdk-23-jdk

# For Windows
# Download and install from https://jdk.java.net/23/
```

### 2. Update Maven Configuration
1. Replace the existing pom.xml with the updated Java 23 version:
```bash
cp pom.xml.java23 pom.xml
```

2. Verify Maven is using Java 23:
```bash
mvn -v
```

### 3. Set Up IDE for Java 23
- For IntelliJ IDEA:
  - Go to File > Project Structure > Project
  - Set Project SDK to Java 23
  - Set Project language level to "23 (Preview features)"
  
- For Eclipse:
  - Go to Window > Preferences > Java > Compiler
  - Set Compiler compliance level to 23
  - Enable preview features

## Phase 2: Dependency Updates

### 1. Update Core Dependencies
The pom.xml has been updated with the latest versions of all dependencies. Key updates include:

- LMAX Disruptor: 3.4.2 → 4.0.0
- SLF4J: 1.7.36 → 2.0.12
- Lombok: 1.18.24 → 1.18.32
- Eclipse Collections: 11.0.0 → 11.1.0

### 2. Test Compilation
```bash
mvn clean compile
```

Fix any compilation errors related to updated dependencies.

## Phase 3: Code Migration

### 1. Update Deprecated APIs

#### Collections API
- Replace `Hashtable` with `ConcurrentHashMap`
- Replace `Vector` with `ArrayList` or `CopyOnWriteArrayList`
- Replace `Stack` with `ArrayDeque`
- Update to Java 8+ collection methods (e.g., `forEach`, `stream`)

#### Date and Time API
- Replace `java.util.Date` with `java.time` classes
- Replace `Calendar` with `LocalDate`, `LocalTime`, `LocalDateTime`, or `ZonedDateTime`
- Update time formatting to use `DateTimeFormatter`

#### I/O and NIO
- Update to use NIO.2 file operations
- Replace `FileInputStream`/`FileOutputStream` with `Files` methods
- Use try-with-resources for all closeable resources

### 2. Apply Java 23 Features

#### Pattern Matching for instanceof
```java
// Before
if (obj instanceof Order) {
    Order order = (Order) obj;
    processOrder(order);
}

// After
if (obj instanceof Order order) {
    processOrder(order);
}
```

#### Switch Expressions
```java
// Before
String result;
switch (orderType) {
    case GTC:
        result = "Good Till Cancel";
        break;
    case IOC:
        result = "Immediate or Cancel";
        break;
    case FOK:
        result = "Fill or Kill";
        break;
    default:
        result = "Unknown";
}

// After
String result = switch (orderType) {
    case GTC -> "Good Till Cancel";
    case IOC -> "Immediate or Cancel";
    case FOK -> "Fill or Kill";
    default -> "Unknown";
};
```

#### Records
```java
// Before
@Value
public class TradeEvent {
    long timestamp;
    long price;
    long size;
}

// After
public record TradeEvent(long timestamp, long price, long size) {}
```

#### Text Blocks
```java
// Before
String sql = "SELECT * " +
             "FROM orders " +
             "WHERE symbol = ? " +
             "AND price > ?";

// After
String sql = """
             SELECT *
             FROM orders
             WHERE symbol = ?
             AND price > ?
             """;
```

#### Sealed Classes
```java
// Before
public abstract class Order {
    // ...
}

// After
public sealed abstract class Order permits GtcOrder, IocOrder, FokOrder {
    // ...
}
```

### 3. Update Concurrency Code

#### Virtual Threads
```java
// Before
ExecutorService executor = Executors.newFixedThreadPool(100);

// After
ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
```

#### Structured Concurrency
```java
// Before
CompletableFuture<OrderBook> orderBookFuture = CompletableFuture.supplyAsync(() -> fetchOrderBook(symbol));
CompletableFuture<UserBalance> balanceFuture = CompletableFuture.supplyAsync(() -> fetchUserBalance(userId));

OrderBook orderBook = orderBookFuture.get();
UserBalance balance = balanceFuture.get();

// After
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    Future<OrderBook> orderBookFuture = scope.fork(() -> fetchOrderBook(symbol));
    Future<UserBalance> balanceFuture = scope.fork(() -> fetchUserBalance(userId));
    
    scope.join();
    scope.throwIfFailed();
    
    OrderBook orderBook = orderBookFuture.resultNow();
    UserBalance balance = balanceFuture.resultNow();
}
```

## Phase 4: Testing

### 1. Unit Tests
```bash
mvn test
```

Fix any test failures related to Java 23 migration.

### 2. Integration Tests
```bash
mvn -Pit test
```

### 3. Performance Tests
```bash
mvn -Dtest=PerfLatency#testLatencyMargin test
mvn -Dtest=PerfThroughput#testThroughputMargin test
mvn -Dtest=PerfHiccups#testHiccups test
```

Compare performance metrics with Java 8 baseline.

## Phase 5: Optimization

### 1. GC Tuning
Experiment with different garbage collectors:

- G1GC (default)
```bash
java -XX:+UseG1GC -jar exchange-core.jar
```

- ZGC (low latency)
```bash
java -XX:+UseZGC -XX:+ZGenerational -jar exchange-core.jar
```

- Shenandoah (low pause)
```bash
java -XX:+UseShenandoahGC -jar exchange-core.jar
```

### 2. JIT Compiler Tuning
```bash
java -XX:+TieredCompilation -XX:+UseStringDeduplication -jar exchange-core.jar
```

### 3. Memory Management
Consider using the Foreign Memory API for performance-critical sections:

```java
try (Arena arena = Arena.ofConfined()) {
    MemorySegment segment = arena.allocate(1024);
    // Use segment for high-performance memory operations
}
```

## Phase 6: Deployment

### 1. Update CI/CD Pipeline
- Update CI/CD configuration to use Java 23
- Add JDK 23 to build matrix
- Update Docker images to use Java 23

### 2. Documentation
- Update system requirements to specify Java 23
- Document any API changes
- Update performance characteristics

### 3. Release
- Create a new release with Java 23 support
- Update version number to reflect major change (e.g., 0.6.0)
- Provide migration guide for users

## Troubleshooting Common Issues

### 1. Compilation Errors
- Check for deprecated API usage
- Verify compatibility with updated dependencies
- Look for raw type warnings that are now errors

### 2. Runtime Errors
- Check for reflection usage that might be affected by stronger encapsulation
- Verify serialization compatibility
- Check for assumptions about JVM behavior that might have changed

### 3. Performance Regressions
- Profile the application to identify bottlenecks
- Adjust GC settings
- Consider reverting specific changes that cause significant regressions

## Rollback Plan

If critical issues are encountered:

1. Revert to the original pom.xml
2. Restore any modified source files
3. Return to Java 8 for development and deployment
4. Document the issues encountered for future migration attempts
