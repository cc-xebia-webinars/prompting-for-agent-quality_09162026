package com.feequote.cli;

import static org.assertj.core.api.Assertions.assertThat;

import com.feequote.clients.PaymentClient;
import com.feequote.services.TransferService;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.boot.DefaultApplicationArguments;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

class QuoteRunnerTest {

    private final ObjectMapper json = new ObjectMapper();
    private final ByteArrayOutputStream out = new ByteArrayOutputStream();
    private final ByteArrayOutputStream err = new ByteArrayOutputStream();

    private int run(String... arguments) {
        QuoteRunner runner = new QuoteRunner(new TransferService(new PaymentClient()), json);
        return runner.runQuote(
                new DefaultApplicationArguments(arguments),
                new PrintStream(out, true, StandardCharsets.UTF_8),
                new PrintStream(err, true, StandardCharsets.UTF_8));
    }

    private JsonNode stdout() throws Exception {
        return json.readTree(out.toString(StandardCharsets.UTF_8));
    }

    @Test
    void printsTheQuoteAsJsonOnStdout() throws Exception {
        int exitCode = run("quote", "--amount=123500", "--from=AU", "--to=AU");

        assertThat(exitCode).isZero();
        assertThat(stdout().get("feeCents").asLong()).isEqualTo(1112);
        assertThat(stdout().get("totalCents").asLong()).isEqualTo(124612);
        assertThat(stdout().get("breakdown").get(0).get("label").asString()).isEqualTo("domesticFee");
    }

    @Test
    void countryAndCurrencyDefaultToTheDomesticSettings() throws Exception {
        int exitCode = run("quote", "--amount=100000");

        assertThat(exitCode).isZero();
        assertThat(stdout().get("feeCents").asLong()).isEqualTo(900);
    }

    @Test
    void theTransferIdCanBeSuppliedOrGenerated() throws Exception {
        assertThat(run("quote", "--amount=100000", "--id=tr-9")).isZero();
        assertThat(stdout().get("transferId").asString()).isEqualTo("tr-9");
    }

    @Test
    void anUnsupportedCountryIsReportedOnStderrWithANonZeroExitCode() {
        int exitCode = run("quote", "--amount=100000", "--to=ZZ");

        assertThat(exitCode).isEqualTo(2);
        assertThat(out.toString(StandardCharsets.UTF_8)).isEmpty();
        assertThat(err.toString(StandardCharsets.UTF_8)).contains("unsupported destination country: ZZ");
    }

    @Test
    void aMissingAmountIsReportedOnStderrWithANonZeroExitCode() {
        int exitCode = run("quote");

        assertThat(exitCode).isEqualTo(2);
        assertThat(err.toString(StandardCharsets.UTF_8)).contains("--amount is required");
    }

    @Test
    void anAmountThatIsNotAWholeNumberIsRejected() {
        int exitCode = run("quote", "--amount=1235.00");

        assertThat(exitCode).isEqualTo(2);
        assertThat(err.toString(StandardCharsets.UTF_8)).contains("whole number of cents");
    }

    @Test
    void theQuoteCommandIsRecognizedFromTheRawArguments() {
        assertThat(QuoteRunner.isQuoteCommand(new String[] {"quote", "--amount=1"})).isTrue();
        assertThat(QuoteRunner.isQuoteCommand(new String[] {})).isFalse();
        assertThat(QuoteRunner.isQuoteCommand(new String[] {"--server.port=9000"})).isFalse();
    }
}
