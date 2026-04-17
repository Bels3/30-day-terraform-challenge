<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multi-Region HA Dashboard | Day 27</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: #e2e8f0;
            padding: 20px;
        }

        .dashboard {
            max-width: 1100px;
            width: 100%;
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            border: 1px solid rgba(59, 130, 246, 0.2);
        }

        .header {
            text-align: center;
            margin-bottom: 40px;
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 10px;
        }

        .subtitle {
            color: #94a3b8;
            font-size: 1.1rem;
        }

        .badge {
            display: inline-block;
            background: rgba(59, 130, 246, 0.2);
            padding: 6px 20px;
            border-radius: 20px;
            color: #93c5fd;
            font-weight: 600;
            margin-top: 15px;
        }

        .architecture-diagram {
            display: flex;
            justify-content: space-between;
            align-items: stretch;
            margin: 40px 0;
            gap: 20px;
            flex-wrap: wrap;
        }

        .region-card {
            flex: 1;
            min-width: 300px;
            background: rgba(51, 65, 85, 0.5);
            border-radius: 16px;
            padding: 25px;
            border: 2px solid;
            transition: all 0.3s ease;
        }

        .region-primary {
            border-color: #10b981;
            box-shadow: 0 0 20px rgba(16, 185, 129, 0.2);
        }

        .region-secondary {
            border-color: #f59e0b;
            box-shadow: 0 0 20px rgba(245, 158, 11, 0.2);
        }

        .region-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 20px;
            font-size: 1.5rem;
            font-weight: 700;
        }

        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-active {
            background: rgba(16, 185, 129, 0.2);
            color: #34d399;
            border: 1px solid rgba(16, 185, 129, 0.3);
        }

        .status-standby {
            background: rgba(245, 158, 11, 0.2);
            color: #fbbf24;
            border: 1px solid rgba(245, 158, 11, 0.3);
        }

        .tier-list {
            margin: 20px 0;
        }

        .tier-item {
            display: flex;
            align-items: center;
            padding: 12px;
            margin: 8px 0;
            background: rgba(15, 23, 42, 0.3);
            border-radius: 8px;
        }

        .tier-icon {
            width: 40px;
            font-size: 1.5rem;
        }

        .tier-info {
            flex: 1;
        }

        .tier-name {
            font-weight: 600;
            color: #e2e8f0;
        }

        .tier-detail {
            font-size: 0.85rem;
            color: #94a3b8;
        }

        .health-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #10b981;
            box-shadow: 0 0 10px #10b981;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .divider {
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            color: #60a5fa;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-top: 30px;
        }

        .stat-card {
            background: rgba(15, 23, 42, 0.5);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
        }

        .stat-value {
            font-size: 1.8rem;
            font-weight: 700;
            color: #60a5fa;
        }

        .stat-label {
            color: #94a3b8;
            margin-top: 8px;
        }

        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(148, 163, 184, 0.2);
            color: #64748b;
        }

        .highlight {
            color: #60a5fa;
            font-weight: 600;
        }

        .info-box {
            background: rgba(59, 130, 246, 0.1);
            border-radius: 8px;
            padding: 12px;
            margin-top: 15px;
            border: 1px solid rgba(59, 130, 246, 0.2);
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>🌍 Global Traffic Management</h1>
            <div class="subtitle">3-Tier Multi-Region High Availability Architecture</div>
            <div class="badge">${environment} Environment | 30-Day Terraform Challenge Day 27</div>
        </div>

        <div class="architecture-diagram">
            <!-- Primary Region -->
            <div class="region-card region-primary">
                <div class="region-header">
                    <span>🌍</span>
                    <span>${primary_region}</span>
                    <span class="status-badge status-active">● ACTIVE PRIMARY</span>
                </div>
                
                <div class="tier-list">
                    <div class="tier-item">
                        <span class="tier-icon">⚖️</span>
                        <div class="tier-info">
                            <div class="tier-name">Web Tier - ALB</div>
                            <div class="tier-detail">Internet-facing • Cross-AZ Load Balancing</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                    
                    <div class="tier-item">
                        <span class="tier-icon">🖥️</span>
                        <div class="tier-info">
                            <div class="tier-name">Application Tier - EC2 ASG</div>
                            <div class="tier-detail">${min_size}-${max_size} Instances • Auto-scaling Enabled</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                    
                    <div class="tier-item">
                        <span class="tier-icon">🗄️</span>
                        <div class="tier-info">
                            <div class="tier-name">Database Tier - RDS</div>
                            <div class="tier-detail">Multi-AZ • Primary Write Instance</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                </div>

                <div class="info-box">
                    <strong>📍 Availability Zones:</strong> ${az_list}<br>
                    <strong>✅ Health Status:</strong> All systems operational
                </div>
            </div>

            <!-- Divider -->
            <div class="divider">
                <span>⟷</span>
            </div>

            <!-- Secondary Region -->
            <div class="region-card region-secondary">
                <div class="region-header">
                    <span>🌎</span>
                    <span>${secondary_region}</span>
                    <span class="status-badge status-standby">○ STANDBY SECONDARY</span>
                </div>
                
                <div class="tier-list">
                    <div class="tier-item">
                        <span class="tier-icon">⚖️</span>
                        <div class="tier-info">
                            <div class="tier-name">Web Tier - ALB</div>
                            <div class="tier-detail">Internet-facing • Ready for Failover</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                    
                    <div class="tier-item">
                        <span class="tier-icon">🖥️</span>
                        <div class="tier-info">
                            <div class="tier-name">Application Tier - EC2 ASG</div>
                            <div class="tier-detail">${min_size}-${max_size} Instances • Warm Standby</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                    
                    <div class="tier-item">
                        <span class="tier-icon">📖</span>
                        <div class="tier-info">
                            <div class="tier-name">Database Tier - RDS</div>
                            <div class="tier-detail">Cross-Region Read Replica • Async Replication</div>
                        </div>
                        <span class="health-indicator"></span>
                    </div>
                </div>

                <div class="info-box">
                    <strong>📍 Availability Zones:</strong> ${secondary_az_list}<br>
                    <strong>🔄 Replication Lag:</strong> &lt; 1 second • Continuous Sync
                </div>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">99.99%</div>
                <div class="stat-label">SLA with Multi-Region</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">2</div>
                <div class="stat-label">Active Regions</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${min_size}-${max_size}</div>
                <div class="stat-label">Instances per Region</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">Terraform</div>
                <div class="stat-label">Infrastructure as Code</div>
            </div>
        </div>

        <div class="footer">
            <span class="highlight">Beldine Oluoch</span> • 
            Day 27: 3-Tier Multi-Region HA • 
            <span style="color: #60a5fa;">github.com/Bels3/30-day-terraform-challenge</span>
            <br><br>
            <span style="font-size: 0.85rem;">
                🏗️ Built with: VPC • ALB • EC2 Auto Scaling • RDS Multi-AZ • Cross-Region Replication
            </span>
        </div>
    </div>
</body>
</html>
