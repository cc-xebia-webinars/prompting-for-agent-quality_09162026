using System.Text.RegularExpressions;

namespace FeeQuote.Web.Tests;

/// <summary>
/// Source-level rules that the compiler cannot express. These are plain file
/// scans so the same check can run in CI without extra tooling.
/// </summary>
public sealed partial class ArchitectureTests
{
    private static readonly string[] SkippedDirectories = ["bin", "obj", "node_modules"];

    // Paths (relative to src/FeeQuote.Web) that may still call the legacy helper.
    private static readonly string[] LegacyCallers =
    [
        Path.Combine("Domain", "Legacy") + Path.DirectorySeparatorChar,
        Path.Combine("Domain", "Jobs", "Reconciliation.cs"),
    ];

    [GeneratedRegex(@"\bCalculateFee\b")]
    private static partial Regex LegacyHelperReference();

    [Fact]
    public void ProductionCode_DoesNotCallLegacyFeeHelper()
    {
        var sourceRoot = Path.Combine(FindRepositoryRoot(), "src", "FeeQuote.Web");
        var offenders = new List<string>();

        foreach (var file in EnumerateSourceFiles(sourceRoot))
        {
            var relative = Path.GetRelativePath(sourceRoot, file);
            if (LegacyCallers.Any(allowed => relative.StartsWith(allowed, StringComparison.Ordinal)))
            {
                continue;
            }

            var lines = File.ReadAllLines(file);
            for (var i = 0; i < lines.Length; i++)
            {
                if (LegacyHelperReference().IsMatch(lines[i]))
                {
                    offenders.Add($"{relative}:{i + 1}");
                }
            }
        }

        Assert.True(
            offenders.Count == 0,
            "New code must not call the legacy fee helper. Use core pricing (PriceWithPolicy or ComputeFee) instead. "
            + "See ticket 4821. Found in: " + string.Join(", ", offenders));
    }

    [Fact]
    public void RepositoryRoot_ContainsExpectedLayout()
    {
        var root = FindRepositoryRoot();

        Assert.True(File.Exists(Path.Combine(root, "FeeQuote.sln")));
        Assert.True(Directory.Exists(Path.Combine(root, "src", "FeeQuote.Web", "Domain")));
    }

    private static IEnumerable<string> EnumerateSourceFiles(string directory)
    {
        foreach (var file in Directory.EnumerateFiles(directory, "*.cs"))
        {
            yield return file;
        }

        foreach (var child in Directory.EnumerateDirectories(directory))
        {
            if (SkippedDirectories.Contains(Path.GetFileName(child), StringComparer.Ordinal))
            {
                continue;
            }

            foreach (var file in EnumerateSourceFiles(child))
            {
                yield return file;
            }
        }
    }

    private static string FindRepositoryRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "FeeQuote.sln")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        throw new InvalidOperationException("FeeQuote.sln not found above " + AppContext.BaseDirectory);
    }
}
