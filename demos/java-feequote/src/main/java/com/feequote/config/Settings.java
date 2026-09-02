package com.feequote.config;

import java.util.List;
import java.util.Set;

/**
 * Static configuration: supported currencies, countries and channels.
 *
 * <p>These are deliberately plain constants. Anything that needs to vary per
 * environment belongs in deployment configuration, not here.
 */
public final class Settings {

    public static final Set<String> CURRENCIES = Set.of("AUD", "NZD", "USD", "GBP", "EUR", "SGD");
    public static final String DEFAULT_CURRENCY = "AUD";

    public static final Set<String> COUNTRIES = Set.of("AU", "NZ", "US", "GB", "IE", "SG", "FJ", "PG");
    public static final String DEFAULT_COUNTRY = "AU";

    public static final List<String> CHANNELS = List.of("online", "branch", "api");
    public static final String DEFAULT_CHANNEL = "online";

    private Settings() {
    }
}
