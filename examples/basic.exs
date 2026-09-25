client = ShadowAITools.Client.new(System.fetch_env!("AQ_API_KEY"))
IO.inspect(ShadowAITools.Client.scan(client, "dns-export.csv"))
