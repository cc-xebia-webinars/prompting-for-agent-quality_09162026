namespace FeeQuote;

public static class Program
{
    public static int Main(string[] args)
    {
        return Cli.Run(args, Console.Out, Console.Error);
    }
}
