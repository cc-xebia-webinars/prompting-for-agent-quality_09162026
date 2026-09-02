package com.feequote;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * Source-level rules for the FeeQuote sources.
 *
 * <p>These tests read the production sources as text so they hold regardless of how a
 * class is imported or statically aliased.
 */
class ArchitectureTest {

    private static final Pattern LEGACY_HELPER = Pattern.compile("\\bcalculateFee\\b");

    private static final Path REPOSITORY_ROOT = findRepositoryRoot();
    private static final Path SOURCE_ROOT = REPOSITORY_ROOT.resolve("src/main/java");
    private static final Path LEGACY_ROOT = SOURCE_ROOT.resolve("com/feequote/legacy");

    // Files that are allowed to reference the legacy helper. The reconciliation job
    // reproduces historical batch totals and must match the batch system until
    // ticket 4821 moves both to core pricing.
    private static final Path RECONCILIATION = SOURCE_ROOT.resolve("com/feequote/jobs/Reconciliation.java");

    private static List<Path> productionSources() {
        try (Stream<Path> tree = Files.walk(SOURCE_ROOT)) {
            return tree.filter(path -> path.toString().endsWith(".java"))
                    .filter(path -> !path.startsWith(LEGACY_ROOT))
                    .filter(path -> !path.equals(RECONCILIATION))
                    .sorted()
                    .toList();
        } catch (IOException unreadable) {
            throw new UncheckedIOException(unreadable);
        }
    }

    private static List<String> referencesTo(Pattern pattern, Path path) {
        try {
            List<String> lines = Files.readAllLines(path);
            List<String> found = new ArrayList<>();
            for (int number = 0; number < lines.size(); number++) {
                if (pattern.matcher(lines.get(number)).find()) {
                    String relative = REPOSITORY_ROOT.relativize(path).toString().replace('\\', '/');
                    found.add(relative + ":" + (number + 1) + ": " + lines.get(number).strip());
                }
            }
            return found;
        } catch (IOException unreadable) {
            throw new UncheckedIOException(unreadable);
        }
    }

    private static Path findRepositoryRoot() {
        Path directory = Paths.get("").toAbsolutePath();
        while (directory != null) {
            if (Files.exists(directory.resolve("pom.xml"))) {
                return directory;
            }
            directory = directory.getParent();
        }
        throw new IllegalStateException("pom.xml not found above " + Paths.get("").toAbsolutePath());
    }

    @Test
    void scanCoversTheServiceAndControllerSources() {
        List<String> scanned = productionSources().stream()
                .map(path -> SOURCE_ROOT.relativize(path).toString().replace('\\', '/'))
                .toList();

        assertThat(scanned).contains(
                "com/feequote/services/TransferService.java",
                "com/feequote/web/QuotesController.java",
                "com/feequote/cli/QuoteRunner.java");
        assertThat(scanned).doesNotContain(
                "com/feequote/jobs/Reconciliation.java",
                "com/feequote/legacy/Fees.java");
    }

    @Test
    void onlyReconciliationReferencesTheLegacyFeeHelper() {
        List<String> offenders = productionSources().stream()
                .flatMap(path -> referencesTo(LEGACY_HELPER, path).stream())
                .toList();

        assertThat(offenders)
                .withFailMessage(
                        "New code must not call the legacy fee helper. Use core pricing "
                        + "(priceWithPolicy or computeFee) instead. See ticket 4821.%n%s",
                        String.join(System.lineSeparator(), offenders))
                .isEmpty();
    }
}
