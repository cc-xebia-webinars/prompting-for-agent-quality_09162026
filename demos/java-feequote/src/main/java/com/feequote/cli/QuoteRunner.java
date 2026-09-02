package com.feequote.cli;

import com.feequote.config.Settings;
import com.feequote.models.Transfer;
import com.feequote.services.TransferService;
import com.feequote.services.TransferValidationException;
import java.io.PrintStream;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ExitCodeGenerator;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

/**
 * Command line entry point.
 *
 * <pre>
 *   java -jar target/feequote.jar quote --amount=123500 --from=AU --to=AU
 * </pre>
 *
 * <p>Prints the quote as JSON on stdout. Validation problems go to stderr with a
 * non-zero exit code so the command is safe to use from scripts. When the quote
 * command is present the application starts without the web server, so the process
 * prints and exits instead of holding a port.
 */
@Component
public class QuoteRunner implements ApplicationRunner, ExitCodeGenerator {

    /** The non-option argument that selects this runner. */
    public static final String COMMAND = "quote";

    private static final int EXIT_OK = 0;
    private static final int EXIT_INVALID = 2;

    private final TransferService transfers;
    private final ObjectMapper json;
    private int exitCode = EXIT_OK;

    public QuoteRunner(TransferService transfers, ObjectMapper json) {
        this.transfers = transfers;
        this.json = json;
    }

    /** True when the process was started to print one quote rather than to serve. */
    public static boolean isQuoteCommand(String[] arguments) {
        return arguments.length > 0 && COMMAND.equals(arguments[0]);
    }

    @Override
    public void run(ApplicationArguments arguments) {
        if (!arguments.getNonOptionArgs().contains(COMMAND)) {
            return;
        }
        exitCode = runQuote(arguments, System.out, System.err);
    }

    @Override
    public int getExitCode() {
        return exitCode;
    }

    /**
     * Prints the quote described by {@code arguments} to {@code out}.
     *
     * @param arguments the parsed command line
     * @param out where the JSON quote is written
     * @param err where a validation problem is reported
     * @return the process exit code
     */
    public int runQuote(ApplicationArguments arguments, PrintStream out, PrintStream err) {
        long amountCents;
        try {
            amountCents = Long.parseLong(required(arguments, "amount"));
        } catch (NumberFormatException notANumber) {
            err.println("error: --amount must be a whole number of cents");
            return EXIT_INVALID;
        } catch (IllegalArgumentException missing) {
            err.println("error: " + missing.getMessage());
            return EXIT_INVALID;
        }

        Transfer transfer = new Transfer(
                option(arguments, "id", "tr-" + UUID.randomUUID().toString().substring(0, 8)),
                amountCents,
                option(arguments, "currency", Settings.DEFAULT_CURRENCY).toUpperCase(Locale.ROOT),
                option(arguments, "from", Settings.DEFAULT_COUNTRY).toUpperCase(Locale.ROOT),
                option(arguments, "to", Settings.DEFAULT_COUNTRY).toUpperCase(Locale.ROOT),
                option(arguments, "channel", Settings.DEFAULT_CHANNEL));

        try {
            out.println(json.writerWithDefaultPrettyPrinter().writeValueAsString(transfers.quote(transfer)));
        } catch (TransferValidationException invalid) {
            err.println("error: " + invalid.getMessage());
            return EXIT_INVALID;
        } catch (JacksonException unwritable) {
            err.println("error: the quote could not be rendered as JSON");
            return EXIT_INVALID;
        }
        return EXIT_OK;
    }

    private static String required(ApplicationArguments arguments, String name) {
        List<String> values = arguments.getOptionValues(name);
        if (values == null || values.isEmpty() || values.get(0).isBlank()) {
            throw new IllegalArgumentException("--" + name + " is required, for example --amount=123500");
        }
        return values.get(0);
    }

    private static String option(ApplicationArguments arguments, String name, String fallback) {
        List<String> values = arguments.getOptionValues(name);
        if (values == null || values.isEmpty() || values.get(0).isBlank()) {
            return fallback;
        }
        return values.get(0);
    }
}
