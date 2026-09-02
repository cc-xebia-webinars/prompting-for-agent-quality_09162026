namespace FeeQuote.Clients;

/// <summary>The payment gateway did not accept the submission.</summary>
public class PaymentGatewayException : Exception
{
    public PaymentGatewayException()
    {
    }

    public PaymentGatewayException(string message)
        : base(message)
    {
    }

    public PaymentGatewayException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

/// <summary>The gateway did not respond in time.</summary>
public class GatewayTimeoutException : PaymentGatewayException
{
    public GatewayTimeoutException()
    {
    }

    public GatewayTimeoutException(string message)
        : base(message)
    {
    }

    public GatewayTimeoutException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

/// <summary>The gateway declined the transfer.</summary>
public class GatewayDeclinedException : PaymentGatewayException
{
    public GatewayDeclinedException()
    {
    }

    public GatewayDeclinedException(string message)
        : base(message)
    {
    }

    public GatewayDeclinedException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
