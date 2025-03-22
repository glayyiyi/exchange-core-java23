# Java 23 Refactoring Examples for Exchange-Core

This document provides concrete examples of how to refactor specific parts of the exchange-core codebase to leverage Java 23 features.

## 1. Order Class Hierarchy with Sealed Classes

### Before:

```java
public abstract class Order {
    private final long orderId;
    private final long uid;
    private final long price;
    private final long size;
    private final OrderAction action;
    
    // Constructor, getters, etc.
    
    public abstract OrderType getOrderType();
}

public class GtcOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.GTC;
    }
}

public class IocOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.IOC;
    }
}

public class FokOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.FOK;
    }
}
```

### After:

```java
public sealed abstract class Order permits GtcOrder, IocOrder, FokOrder {
    private final long orderId;
    private final long uid;
    private final long price;
    private final long size;
    private final OrderAction action;
    
    // Constructor, getters, etc.
    
    public abstract OrderType getOrderType();
}

public final class GtcOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.GTC;
    }
}

public final class IocOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.IOC;
    }
}

public final class FokOrder extends Order {
    @Override
    public OrderType getOrderType() {
        return OrderType.FOK;
    }
}
```

## 2. Event Classes with Records

### Before:

```java
@Value
public class TradeEvent {
    long timestamp;
    long orderId;
    long uid;
    long matchedOrderId;
    long matchedUid;
    long price;
    long size;
    MatcherTradeType tradeType;
}
```

### After:

```java
public record TradeEvent(
    long timestamp,
    long orderId,
    long uid,
    long matchedOrderId,
    long matchedUid,
    long price,
    long size,
    MatcherTradeType tradeType
) {}
```

## 3. Order Processing with Pattern Matching

### Before:

```java
public void processOrder(Order order) {
    if (order.getOrderType() == OrderType.GTC) {
        // Process GTC order
        processGtcOrder((GtcOrder) order);
    } else if (order.getOrderType() == OrderType.IOC) {
        // Process IOC order
        processIocOrder((IocOrder) order);
    } else if (order.getOrderType() == OrderType.FOK) {
        // Process FOK order
        processFokOrder((FokOrder) order);
    } else {
        throw new IllegalArgumentException("Unknown order type: " + order.getOrderType());
    }
}
```

### After:

```java
public void processOrder(Order order) {
    switch (order) {
        case GtcOrder gtcOrder -> processGtcOrder(gtcOrder);
        case IocOrder iocOrder -> processIocOrder(iocOrder);
        case FokOrder fokOrder -> processFokOrder(fokOrder);
    }
}
```

## 4. Concurrent Processing with Virtual Threads

### Before:

```java
public class ReportingService {
    private final ExecutorService executor = Executors.newFixedThreadPool(10);
    
    public CompletableFuture<ReportResult> generateReport(ReportRequest request) {
        return CompletableFuture.supplyAsync(() -> {
            // Generate report
            return new ReportResult();
        }, executor);
    }
    
    public void shutdown() {
        executor.shutdown();
    }
}
```

### After:

```java
public class ReportingService {
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
    
    public CompletableFuture<ReportResult> generateReport(ReportRequest request) {
        return CompletableFuture.supplyAsync(() -> {
            // Generate report
            return new ReportResult();
        }, executor);
    }
    
    public void shutdown() {
        executor.shutdown();
    }
}
```

## 5. Configuration with Text Blocks

### Before:

```java
private static final String CONFIG_TEMPLATE = 
    "{\n" +
    "  \"exchangeId\": \"%s\",\n" +
    "  \"matchingEngine\": {\n" +
    "    \"orderBookType\": \"%s\",\n" +
    "    \"threadAffinity\": %b\n" +
    "  },\n" +
    "  \"risksEngine\": {\n" +
    "    \"marginType\": \"%s\"\n" +
    "  }\n" +
    "}";
```

### After:

```java
private static final String CONFIG_TEMPLATE = """
    {
      "exchangeId": "%s",
      "matchingEngine": {
        "orderBookType": "%s",
        "threadAffinity": %b
      },
      "risksEngine": {
        "marginType": "%s"
      }
    }
    """;
```

## 6. Structured Concurrency for Order Processing

### Before:

```java
public OrderProcessingResult processOrderConcurrently(Order order) throws Exception {
    CompletableFuture<OrderBook> orderBookFuture = CompletableFuture.supplyAsync(() -> fetchOrderBook(order.getSymbol()));
    CompletableFuture<UserBalance> balanceFuture = CompletableFuture.supplyAsync(() -> fetchUserBalance(order.getUid()));
    
    try {
        OrderBook orderBook = orderBookFuture.get();
        UserBalance balance = balanceFuture.get();
        return processOrderWithData(order, orderBook, balance);
    } catch (Exception ex) {
        orderBookFuture.cancel(true);
        balanceFuture.cancel(true);
        throw ex;
    }
}
```

### After:

```java
public OrderProcessingResult processOrderConcurrently(Order order) throws Exception {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        Future<OrderBook> orderBookFuture = scope.fork(() -> fetchOrderBook(order.getSymbol()));
        Future<UserBalance> balanceFuture = scope.fork(() -> fetchUserBalance(order.getUid()));
        
        scope.join();
        scope.throwIfFailed();
        
        OrderBook orderBook = orderBookFuture.resultNow();
        UserBalance balance = balanceFuture.resultNow();
        
        return processOrderWithData(order, orderBook, balance);
    }
}
```

## 7. Memory Management with Foreign Memory API

### Before:

```java
public class DirectMemoryOrderBook {
    private final ByteBuffer buffer;
    
    public DirectMemoryOrderBook(int capacity) {
        this.buffer = ByteBuffer.allocateDirect(capacity);
    }
    
    public void addOrder(long orderId, long price, long size) {
        // Write to direct buffer
        buffer.putLong(orderId);
        buffer.putLong(price);
        buffer.putLong(size);
    }
    
    public void close() {
        // No direct way to free the buffer in Java 8
        // Rely on GC and Cleaner
    }
}
```

### After:

```java
public class DirectMemoryOrderBook implements AutoCloseable {
    private final Arena arena;
    private final MemorySegment segment;
    
    public DirectMemoryOrderBook(int capacity) {
        this.arena = Arena.ofConfined();
        this.segment = arena.allocate(capacity);
    }
    
    public void addOrder(long orderId, long price, long size) {
        // Write to memory segment
        MemoryAccess.setLongAtOffset(segment, 0, orderId);
        MemoryAccess.setLongAtOffset(segment, 8, price);
        MemoryAccess.setLongAtOffset(segment, 16, size);
    }
    
    @Override
    public void close() {
        arena.close(); // Explicitly free the memory
    }
}
```

## 8. Switch Expressions for Command Handling

### Before:

```java
public ApiCommandResult handleCommand(ApiCommand command) {
    switch (command.getCommandType()) {
        case PLACE_ORDER:
            return handlePlaceOrder((ApiPlaceOrder) command);
        case CANCEL_ORDER:
            return handleCancelOrder((ApiCancelOrder) command);
        case MOVE_ORDER:
            return handleMoveOrder((ApiMoveOrder) command);
        case ADD_USER:
            return handleAddUser((ApiAddUser) command);
        case ADJUST_USER_BALANCE:
            return handleAdjustBalance((ApiAdjustUserBalance) command);
        default:
            throw new IllegalArgumentException("Unknown command type: " + command.getCommandType());
    }
}
```

### After:

```java
public ApiCommandResult handleCommand(ApiCommand command) {
    return switch (command) {
        case ApiPlaceOrder placeOrder -> handlePlaceOrder(placeOrder);
        case ApiCancelOrder cancelOrder -> handleCancelOrder(cancelOrder);
        case ApiMoveOrder moveOrder -> handleMoveOrder(moveOrder);
        case ApiAddUser addUser -> handleAddUser(addUser);
        case ApiAdjustUserBalance adjustBalance -> handleAdjustBalance(adjustBalance);
        default -> throw new IllegalArgumentException("Unknown command type: " + command.getCommandType());
    };
}
```

These examples demonstrate how to leverage Java 23 features to make the exchange-core code more concise, readable, and maintainable while potentially improving performance in key areas.
