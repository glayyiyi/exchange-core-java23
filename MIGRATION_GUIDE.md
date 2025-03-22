# Migration Guide to Java 23

This guide outlines the steps taken to migrate the exchange-core project from Java 8 to Java 23.

## Key Changes

### 1. Maven Configuration Updates

- Updated Java version from 1.8 to 23
- Added `maven.compiler.release=23` property
- Updated Maven plugins to support Java 23
- Added `--enable-preview` flag to enable preview features

### 2. Dependency Updates

| Dependency | Old Version | New Version | Notes |
|------------|------------|------------|-------|
| JNA | 5.11.0 | 5.14.0 | Latest version with Java 23 support |
| LMAX Disruptor | 3.4.2 | 4.0.0 | Major version update with Java 17+ support |
| Lombok | 1.18.24 | 1.18.32 | Latest version with Java 23 support |
| SLF4J | 1.7.36 | 2.0.12 | Major version update |
| OpenHFT Affinity | 3.2.2 | 3.24.0 | Latest version |
| Chronicle-Wire | 2.19.1 | 2.24.0 | Latest version |
| Agrona | 1.15.1 | 1.20.0 | Latest version |
| Eclipse Collections | 11.0.0 | 11.1.0 | Latest version |
| Mockito | 4.5.1 | 5.10.0 | Latest version |
| Logback | 1.2.11 | 1.4.14 | Latest version |
| Guava | 31.1-jre | 33.0.0-jre | Latest version |
| Commons Lang | 3.12.0 | 3.14.0 | Latest version |
| JUnit | 5.8.2 | 5.10.2 | Latest version |
| Hamcrest | 1.3 | 2.2 | Latest version |
| Cucumber | 7.2.3 | 7.15.0 | Latest version |

### 3. Code Changes

#### Removed APIs

- Replaced deprecated collection methods with modern alternatives
- Updated to new time API methods where applicable
- Replaced `java.util.Date` with `java.time` API where possible

#### New Java Features Used

- Pattern matching for instanceof
- Switch expressions
- Text blocks for multiline strings
- Records for simple data carriers
- Enhanced NullPointerException messages
- Sealed classes where appropriate
- Virtual threads for improved concurrency

### 4. Build System Updates

- Updated Maven plugins to latest versions
- Added support for preview features
- Updated Javadoc configuration

## Testing Strategy

1. Run unit tests with Java 23
2. Run integration tests with Java 23
3. Run performance tests to compare with Java 8 baseline
4. Verify serialization compatibility with previous versions

## Known Issues

- [List any known issues or incompatibilities]

## Performance Impact

- [Summary of performance changes after migration]
