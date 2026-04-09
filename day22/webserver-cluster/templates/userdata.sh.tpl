#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y apache2

systemctl start apache2
systemctl enable apache2

# Write HTML using tee to avoid heredoc conflicts
tee /var/www/html/index.html > /dev/null << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Day 22 - Putting It All Together</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0d1117; color: #e6edf3; font-family: 'Segoe UI', system-ui, sans-serif; min-height: 100vh; padding: 40px 20px; }
    .container { max-width: 900px; margin: 0 auto; }
    .badge { display: inline-block; background: #ff9900; color: #0d1117; font-weight: 700; font-size: 13px; padding: 4px 14px; border-radius: 20px; letter-spacing: 1px; margin-bottom: 20px; }
    h1 { font-size: 2.4rem; font-weight: 800; color: #ff9900; line-height: 1.2; margin-bottom: 8px; }
    .subtitle { color: #8b949e; font-size: 1rem; margin-bottom: 40px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 20px; margin-bottom: 40px; }
    .card { background: #161b27; border: 1px solid #30363d; border-radius: 10px; padding: 24px; }
    .card h3 { color: #ff9900; font-size: 0.85rem; font-weight: 600; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 16px; }
    .insight { font-size: 0.95rem; color: #e6edf3; line-height: 1.7; margin-bottom: 12px; padding-left: 12px; border-left: 2px solid #ff9900; }
    .stack-row { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; }
    .tag { border: 1px solid #30363d; border-radius: 6px; padding: 4px 10px; font-size: 0.8rem; color: #8b949e; }
    .tag.green { border-color: #3fb950; color: #3fb950; }
    .tag.orange { border-color: #ff9900; color: #ff9900; }
    .tag.blue { border-color: #58a6ff; color: #58a6ff; }
    .terminal { background: #161b27; border: 1px solid #30363d; border-radius: 10px; padding: 24px; margin-bottom: 40px; }
    .terminal h3 { color: #8b949e; font-size: 0.8rem; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 16px; }
    .line { font-family: 'Courier New', monospace; font-size: 0.88rem; margin-bottom: 6px; }
    .line.green { color: #3fb950; }
    .line.orange { color: #ff9900; }
    .line.dim { color: #8b949e; }
    .line.white { color: #e6edf3; }
    .pipeline { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; margin-bottom: 40px; }
    .step { background: #161b27; border: 1px solid #30363d; border-radius: 8px; padding: 10px 18px; font-size: 0.85rem; color: #e6edf3; text-align: center; }
    .step.active { border-color: #ff9900; color: #ff9900; }
    .arrow { color: #30363d; font-size: 1.2rem; }
    .footer { text-align: center; color: #8b949e; font-size: 0.8rem; padding-top: 20px; border-top: 1px solid #30363d; }
  </style>
</head>
<body>
  <div class="container">
    <span class="badge">DAY 22 OF 30</span>
    <h1>Putting It All Together</h1>
    <p class="subtitle">Integrated Pipeline &middot; Sentinel Policies &middot; Immutable Artifacts &middot; eu-west-1</p>
    <div class="pipeline">
      <div class="step">Git Push</div>
      <span class="arrow">&#8594;</span>
      <div class="step">fmt + validate</div>
      <span class="arrow">&#8594;</span>
      <div class="step">terraform test</div>
      <span class="arrow">&#8594;</span>
      <div class="step active">plan artifact</div>
      <span class="arrow">&#8594;</span>
      <div class="step">Sentinel check</div>
      <span class="arrow">&#8594;</span>
      <div class="step">Cost gate</div>
      <span class="arrow">&#8594;</span>
      <div class="step">apply</div>
    </div>
    <div class="grid">
      <div class="card">
        <h3>Key Insights From 22 Days</h3>
        <p class="insight">The saved plan file is the immutable artifact. What was reviewed is exactly what gets applied.</p>
        <p class="insight">State is not a backup. It is the source of truth. Remote, locked, encrypted.</p>
        <p class="insight">Sentinel policies are infrastructure contracts encoded as code, not documentation nobody reads.</p>
      </div>
      <div class="card">
        <h3>What This Instance Proves</h3>
        <p class="insight">IMDSv2 enforced. Instance metadata requires signed tokens. No SSRF to metadata attacks.</p>
        <p class="insight">Every resource tagged ManagedBy = terraform. Sentinel blocked the apply until this was true.</p>
        <p class="insight">CloudWatch watching CPU, unhealthy hosts, and zero requests. Silence is also a signal.</p>
      </div>
      <div class="card">
        <h3>Stack</h3>
        <div class="stack-row">
          <span class="tag orange">Terraform 1.14.7</span>
          <span class="tag orange">AWS eu-west-1</span>
          <span class="tag green">GitHub Actions CI</span>
          <span class="tag green">Sentinel Policies</span>
          <span class="tag blue">S3 Remote State</span>
          <span class="tag blue">CloudWatch</span>
          <span class="tag blue">SNS Alerts</span>
        </div>
      </div>
    </div>
    <div class="terminal">
      <h3>Pipeline Output</h3>
      <p class="line green">&#10003; terraform fmt -check -recursive ... passed</p>
      <p class="line green">&#10003; terraform validate ... success</p>
      <p class="line green">&#10003; terraform test ... 3 passed, 0 failed</p>
      <p class="line green">&#10003; terraform plan -out=day22.tfplan ... saved</p>
      <p class="line orange">&#8594; Sentinel: require-instance-type ... PASS</p>
      <p class="line orange">&#8594; Sentinel: require-terraform-tag ... PASS</p>
      <p class="line dim">~ cost estimation: free tier - policy written, gate ready</p>
      <p class="line green">&#10003; terraform apply "day22.tfplan" ... Apply complete!</p>
      <p class="line white">&nbsp;&nbsp;Resources: 17 added, 0 changed, 0 destroyed</p>
    </div>
    <div class="footer">
      Beldine Oluoch &nbsp;&middot;&nbsp; eu-west-1 &nbsp;&middot;&nbsp; Terraform v1.14.7 &nbsp;&middot;&nbsp; 30-Day Terraform Challenge
    </div>
  </div>
</body>
</html>
HTMLEOF

# Configure Apache to serve on the correct port
sed -i "s/Listen 80/Listen ${server_port}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${server_port}>/" /etc/apache2/sites-enabled/000-default.conf

systemctl restart apache2
