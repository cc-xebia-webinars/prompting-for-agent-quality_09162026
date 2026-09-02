package com.feequote.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class QuotesControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private static String body(String amountCents, String currency, String origin, String destination) {
        return """
                {"amountCents": %s, "currency": "%s", "originCountry": "%s", "destinationCountry": "%s"}
                """.formatted(amountCents, currency, origin, destination);
    }

    @Test
    void plainDomesticTransferReturnsAQuoteWithItsBreakdown() throws Exception {
        mockMvc.perform(post("/api/quotes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("100000", "AUD", "AU", "AU")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.amountCents").value(100000))
                .andExpect(jsonPath("$.currency").value("AUD"))
                .andExpect(jsonPath("$.feeCents").value(900))
                .andExpect(jsonPath("$.totalCents").value(100900))
                .andExpect(jsonPath("$.breakdown.length()").value(1))
                .andExpect(jsonPath("$.breakdown[0].label").value("domesticFee"))
                .andExpect(jsonPath("$.breakdown[0].amountCents").value(900));
    }

    @Test
    void ticket4821AmountIsQuotedThroughCorePricing() throws Exception {
        mockMvc.perform(post("/api/quotes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("123500", "aud", "au", "au")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.feeCents").value(1112));
    }

    @Test
    void anUnsupportedCurrencyIsABadRequest() throws Exception {
        mockMvc.perform(post("/api/quotes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("100000", "XXX", "AU", "AU")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("unsupported currency: XXX"));
    }

    @Test
    void aNonPositiveAmountIsRejectedByTheRequestConstraints() throws Exception {
        mockMvc.perform(post("/api/quotes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("0", "AUD", "AU", "AU")))
                .andExpect(status().isBadRequest());
    }
}
