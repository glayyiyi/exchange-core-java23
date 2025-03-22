# Java 23 Implementation Guide for Exchange-Core

This guide provides detailed instructions for implementing the Java 23 migration for the exchange-core project. It includes specific code examples and step-by-step instructions.

## Step 1: Update Maven Configuration

Replace the existing `pom.xml` with the updated version:

```bash
mv pom.xml.java23 pom.xml
```

## Step 2: Refactor Core Classes

### OrderCommand Class

The `OrderCommand` class has been refactored to remove commented-out code and improve readability. Key changes:

1. Removed unused commented code
2. Improved code formatting
3. Maintained the same functionality

```bash
mv src/main/java/exchange/core2/core/common/cmd/OrderCommand.java.java23 src/main/java/exchange/core2/core/common/cmd/OrderCommand.java
```

### ExchangeCore Class

The `ExchangeCore` class has been refactored to use structured concurrency:

1. Replaced `ExecutorService` and `CompletableFuture` with `StructuredTaskScope`
2. Improved error handling
3. Simplified thread management

```bash
mv src/main/java/exchange/core2/core/ExchangeCore.java.java23 src/main/java/exchange/core2/core/ExchangeCore.java
```

### MatcherTradeEvent Class

The `MatcherTradeEvent` class has been refactored to:

1. Use pattern matching for instanceof
2. Use text blocks for toString()
3. Improve documentation
4. Use the builder pattern more effectively

```bash
mv src/main/java/exchange/core2/core/common/MatcherTradeEvent.java.java23 src/main/java/exchange/core2/core/common/MatcherTradeEvent.java
```

### SingleUserReportQuery Class

The `SingleUserReportQuery` class has been converted to a record:

1. Replaced class with record
2. Removed redundant getters and equals/hashCode
3. Improved documentation

```bash
mv src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java.java23 src/main/java/exchange/core2/core/common/api/reports/SingleUserReportQuery.java
```

## Step 3: Refactor Additional Classes

### Convert Value Classes to Records

Identify simple value classes that can be converted to records:

1. Look for classes with immutable fields
2. Look for classes with equals/hashCode implementations
3. Look for classes with simple constructors and getters

Example pattern:

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

### Apply Pattern Matching

Update instanceof checks to use pattern matching:

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

### Use Switch Expressions

Update switch statements to use switch expressions:

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
    default:
        result = "Unknown";
}

// After
String result = switch (orderType) {
    case GTC -> "Good Till Cancel";
    case IOC -> "Immediate or Cancel";
    default -> "Unknown";
};
```

### Use Text Blocks

Replace multi-line string concatenations with text blocks:

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

## Step 4: Update Concurrency Code

### Replace ExecutorService with Virtual Threads

```java
// Before
ExecutorService executor = Executors.newFixedThreadPool(10);

// After
ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
```

### Use Structured Concurrency

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

## Step 5: Testing

Run tests to verify the changes:

```bash
mvn clean test
```

If tests fail, check for:

1. API changes in updated dependencies
2. Behavior changes in Java 23
3. Issues with pattern matching or records

## Step 6: Performance Testing

Run performance tests to compare with Java 8:

```bash
mvn -Dtest=PerfLatency#testLatencyMargin test
mvn -Dtest=PerfThroughput#testThroughputMargin test
```

## Step 7: Finalize Migration

1. Update documentation
2. Update version number
3. Create a release

## Common Issues and Solutions

### Issue: Disruptor API Changes

**Solution:** Check the Disruptor 4.0.0 documentation for API changes and update code accordingly.

### Issue: Serialization Compatibility

**Solution:** Ensure that records are properly serialized/deserialized by implementing custom serialization if needed.

### Issue: Performance Regression

**Solution:** Profile the application to identify bottlenecks and optimize critical paths.

### Issue: Thread Affinity

**Solution:** Virtual threads may not respect thread affinity settings. Use platform threads for performance-critical components that require thread affinity.

## Conclusion

By following this guide, you should be able to successfully migrate the exchange-core project to Java 23, taking advantage of modern language features while maintaining performance and compatibility.
