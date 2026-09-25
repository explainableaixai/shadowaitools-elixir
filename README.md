# ShadowAITools

Turn a network log into a list of the AI tools people actually use. `ShadowAITools` reads a DNS, proxy or firewall export, extracts every hostname, and looks each one up against the AI tool register. You get back which hosts are AI products, what they do, and how their vendors treat your data. The hosted version, with PDF reports, is the [shadow AI audit service](https://www.shadowaitools.com/shadow-audit.php). This package brings the same check into Elixir code, Livebook notebooks and scheduled jobs.

## Installation

```elixir
{:shadowaitools, "~> 1.0"}
```

In Livebook:

```elixir
Mix.install([{:shadowaitools, "~> 1.0"}])
```

## Scan a file

```elixir
client = ShadowAITools.Client.new(System.fetch_env!("AQ_API_KEY"))
results = ShadowAITools.Client.scan(client, "exports/firewall-2026-09.csv")
```

`scan/2` returns a list with one entry per unique host, in the order first seen. Each entry is the same tagged tuple that `check/2` returns:

- `{:ok, map}` when the lookup succeeded, whether or not the host is an AI tool
- `{:error, {:api_error, status, body}}` when the API answered with an error status
- `{:error, reason}` for transport failures

This matters in practice. A single failed lookup does **not** stop the scan. You get every other result and can retry the failures afterwards.

## Separating hits, misses and failures

```elixir
{ai, rest} =
  Enum.split_with(results, &match?({:ok, %{"blocked" => true}}, &1))

failures = Enum.filter(rest, &match?({:error, _}, &1))
tools = Enum.map(ai, fn {:ok, t} -> t end)
```

From `tools` you can build whatever summary you need. Group by category, for example:

```elixir
tools
|> Enum.group_by(& &1["primary_category"], & &1["domain"])
|> Enum.sort_by(fn {_cat, hosts} -> -length(hosts) end)
```

## How hostnames are extracted

`scan/2` reads the whole file and splits it on whitespace, commas and semicolons. Each piece is parsed as a URI, with `https://` prepended if it has no scheme. Its host is collected, and duplicates are removed with `Enum.uniq/1`.

Things to know before you feed it a real log:

- **It is literal.** Every token that yields a host becomes a lookup, including timestamps, IP addresses and field names. On a wide CSV, extract the hostname column first. `NimbleCSV` or a one-line `cut` does it.
- **Case is kept as written.** `Example.com` and `example.com` count as two hosts. Lower-case the file, or the column, first if your source mixes cases.
- **The file is read in one go.** `File.read!/1` raises if the path is wrong, before any lookup happens. Split very large exports into daily files.

## A notebook workflow

Livebook is a comfortable place for a one-off audit:

1. `Mix.install/1` the package and `Kino`.
2. Upload the export with a `Kino.Input.file/1` cell.
3. Run `scan/2` on the uploaded path.
4. Show the grouped result with `Kino.DataTable.new/1`.

The notebook then serves as both the analysis and its documentation. Save it next to the export as evidence of what was checked and when.

## Concurrency

`scan/2` checks hosts one at a time. That keeps quota use predictable and avoids rate limits. For large host lists where speed matters, do the extraction yourself and use `check/2` with `Task.async_stream/3`:

```elixir
hosts
|> Task.async_stream(&ShadowAITools.Client.check(client, &1),
  max_concurrency: 4, timeout: 30_000)
|> Enum.map(fn {:ok, res} -> res end)
```

## Retries

Lookups use `Req.get/2`, which retries transient failures (timeouts, 408, 429 and common 5xx responses) with backoff before returning. The `{:error, _}` entries you see after a scan are the ones that failed even after those retries. A 401 or 403 in there points at the key or the monthly quota, not the network.

## What each successful map holds

For an AI tool: `"blocked" => true`, `"primary_category"`, `"ai_type"`, a `"categories"` list, and the training fields `"trains_on_data"`, `"opt_out_available"`, `"enterprise_no_training"` and `"api_no_training"`. `"terms_checked"` gives the review date. For anything else, `"blocked"` is `false`.

A value of `"unstated"` records that the vendor terms were read and are silent on the question. In an audit, silence is a finding worth listing.

## Weekly comparison with Oban

Scheduled as an Oban cron job, a weekly scan builds a history. Store each week's set of AI domains in a table, then diff:

```elixir
new_tools = MapSet.difference(this_week, last_week)
```

Newly appearing tools are often the most useful items in a governance report.

## What stays private

Only hostnames are sent, one per request. User names, client addresses and timestamps stay on the machine that runs the scan. Join the results back to your log locally to see who used what.

## Regulatory context

Knowing which AI systems are in use is a starting requirement in the EU AI Act, a control in ISO/IEC 42001 and the first function (Map) of the NIST AI Risk Management Framework. A dated scan result gives auditors a concrete artefact.

## Data behind the scan

Answers come from the same register used by [compliance tools for unapproved AI use](https://www.aitoolsblocklist.com/shadow-ai-audit.php). For a [category check](https://www.urlcategorizationdatabase.com/check-domain.php) on the non-AI remainder of a log, use the URL category data. If some of what you find is automated agents, give them an [AI agent allow list, priced per lookup](https://www.aiagentallowlist.com/pricing.php).

The same scanner is available as [a Go module for command-line scanners](https://pkg.go.dev/github.com/explainableaixai/shadowaitools-go) and on [pub.dev for Dart](https://pub.dev/packages/shadowaitools).

## License

MIT
