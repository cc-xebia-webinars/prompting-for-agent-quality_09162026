using System.Text.RegularExpressions;

namespace FeeQuote.Tests;

/// <summary>
/// Source-level rules that the compiler cannot express. These read the
/// production tree directly so they hold regardless of how code is wired up.
/// </summary>
public class ArchitectureTests
{
    private static readonly Regex LegacyHelperReference = new(@"\bCalculateFee\b", RegexOptions.CultureInvariant);

    private static readonly string[] AllowedLegacyCallers =
    [
        "src/FeeQuote/Legacy/",
        "src/FeeQuote/Jobs/Reconciliation.cs",
    ];

    [Fact]
    public void ProductionCode_OutsideLegacyAndReconciliation_DoesNotReferenceLegacyFeeHelper()
    {
        string root = FindRepositoryRoot();
        string sourceRoot = Path.Combine(root, "src", "FeeQuote");

        List<string> offenders = Directory
            .EnumerateFiles(sourceRoot, "*.cs", SearchOption.AllDirectories)
            .Select(path => Path.GetRelativePath(root, path).Replace('\\', '/'))
            .Where(relative => !IsBuildOutput(relative) && !IsAllowedLegacyCaller(relative))
            .Where(relative => LegacyHelperReference.IsMatch(File.ReadAllText(Path.Combine(root, relative))))
            .OrderBy(relative => relative, StringComparer.Ordinal)
            .ToList();

        Assert.True(
            offenders.Count == 0,
            "New code must not call the legacy fee helper. Use core pricing (PriceWithPolicy or ComputeFee) instead. "
            + "See ticket 4821." + Environment.NewLine
            + "Files referencing CalculateFee: " + string.Join(", ", offenders));
    }

    [Fact]
    public void ArchitectureScan_SeesTheProductionSources()
    {
        // Guards against the scan silently passing because it looked in the wrong place.
        string sourceRoot = Path.Combine(FindRepositoryRoot(), "src", "FeeQuote");

        Assert.True(File.Exists(Path.Combine(sourceRoot, "Services", "TransferService.cs")));
        Assert.True(File.Exists(Path.Combine(sourceRoot, "Legacy", "Fees.cs")));
    }

    private static bool IsAllowedLegacyCaller(string relativePath)
    {
        return AllowedLegacyCallers.Any(allowed => relativePath.StartsWith(allowed, StringComparison.Ordinal));
    }

    private static bool IsBuildOutput(string relativePath)
    {
        return relativePath.Contains("/bin/", StringComparison.Ordinal)
            || relativePath.Contains("/obj/", StringComparison.Ordinal);
    }

    private static string FindRepositoryRoot()
    {
        DirectoryInfo? directory = new(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "FeeQuote.sln")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        throw new InvalidOperationException("Could not find FeeQuote.sln above " + AppContext.BaseDirectory);
    }
}
