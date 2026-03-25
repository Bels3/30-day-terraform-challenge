#!/bin/bash
apt-get update -y
apt-get install -y apache2 curl
systemctl start apache2
systemctl enable apache2

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Day 12 - Zero-Downtime Deployments</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background-color: #0d1117;
      color: #e6edf3;
      font-family: 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 12px;
      padding: 40px 48px;
      max-width: 560px;
      width: 100%;
      text-align: center;
    }
    .challenge {
      font-size: 12px;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: #ff9900;
      margin-bottom: 8px;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      color: #ff9900;
      margin-bottom: 4px;
    }
    .subtitle {
      font-size: 13px;
      color: #8b949e;
      margin-bottom: 28px;
    }
    .badges {
      display: flex;
      justify-content: center;
      gap: 12px;
      margin-bottom: 28px;
      flex-wrap: wrap;
    }
    .badge {
      padding: 6px 18px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 1px;
      text-transform: uppercase;
    }
    .badge-version {
      background: #ff9900;
      color: #0d1117;
    }
    .badge-blue {
      background: #1f6feb;
      color: #ffffff;
    }
    .meta {
      background: #0d1117;
      border: 1px solid #21262d;
      border-radius: 8px;
      padding: 16px 20px;
      text-align: left;
      margin-bottom: 24px;
    }
    .meta-row {
      display: flex;
      justify-content: space-between;
      padding: 5px 0;
      font-size: 13px;
      border-bottom: 1px solid #21262d;
    }
    .meta-row:last-child { border-bottom: none; }
    .meta-label { color: #8b949e; }
    .meta-value { color: #e6edf3; font-family: monospace; }
    .footer {
      font-size: 12px;
      color: #8b949e;
    }
    .footer span { color: #ff9900; }
  </style>
</head>
<body>
  <div class="card">
    <p class="challenge">30-Day Terraform Challenge</p>
    <h1>Zero-Downtime Deployments</h1>
    <p class="subtitle">Day 12 — create_before_destroy + Blue/Green Strategy</p>
    <div class="badges">
      <span class="badge badge-version">Version 2</span>
      <span class="badge badge-blue">Blue Environment</span>
    </div>
    <div class="meta">
      <div class="meta-row">
        <span class="meta-label">Instance ID</span>
        <span class="meta-value">$INSTANCE_ID</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Availability Zone</span>
        <span class="meta-value">$AZ</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Deployment Strategy</span>
        <span class="meta-value">create_before_destroy</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">Load Balancer</span>
        <span class="meta-value">Application (ALB)</span>
      </div>
    </div>
    <p class="footer">Deployed by <span>Beldine Oluoch</span> · eu-west-1 · Terraform v1.14.7</p>
  </div>
</body>
</html>
EOF
