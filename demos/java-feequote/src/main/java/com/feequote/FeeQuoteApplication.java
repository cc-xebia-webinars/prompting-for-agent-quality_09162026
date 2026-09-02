package com.feequote;

import com.feequote.cli.QuoteRunner;
import java.util.Map;
import org.springframework.boot.Banner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

/**
 * FeeQuote runs two ways from the same jar: as a service (the default) and as a one
 * shot command that prints a single quote. The command form starts without the web
 * server, so it prints to stdout and exits with a usable status code instead of
 * holding a port.
 */
@SpringBootApplication
public class FeeQuoteApplication {

    public static void main(String[] arguments) {
        SpringApplication application = new SpringApplication(FeeQuoteApplication.class);

        if (!QuoteRunner.isQuoteCommand(arguments)) {
            application.run(arguments);
            return;
        }

        application.setWebApplicationType(WebApplicationType.NONE);
        application.setBannerMode(Banner.Mode.OFF);
        application.setLogStartupInfo(false);
        application.setDefaultProperties(Map.of("logging.level.root", "WARN"));
        try (ConfigurableApplicationContext context = application.run(arguments)) {
            System.exit(SpringApplication.exit(context));
        }
    }
}
