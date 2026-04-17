#!/bin/bash
apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Auto Scaling | ${owner}</title>
    <style>
        body { font-family: Arial; background: #0a0e27; color: #fff; padding: 20px; text-align: center; }
        .btn { padding: 15px 30px; background: #667eea; color: #fff; border: none; border-radius: 8px; font-size: 18px; cursor: pointer; margin: 20px; }
        .server { display: inline-block; width: 100px; padding: 20px; margin: 10px; background: #1e293b; border-radius: 10px; }
        .active { background: #10b981; }
        .cpu-bar { width: 300px; height: 30px; background: #1e293b; margin: 20px auto; border-radius: 15px; overflow: hidden; }
        .cpu-fill { height: 100%; background: #10b981; width: 35%; transition: width 0.3s; color: #fff; line-height: 30px; }
    </style>
</head>
<body>
    <h1>Auto Scaling Live Demo</h1>
    <p>Environment: ${environment} | Owner: ${owner}</p>
    
    <h2>Servers: <span id="count">2</span>/4</h2>
    <div id="servers">
        <div class="server active">S1</div>
        <div class="server active">S2</div>
        <div class="server">S3</div>
        <div class="server">S4</div>
    </div>
    
    <h3>CPU: <span id="cpu-val">35</span>%</h3>
    <div class="cpu-bar">
        <div class="cpu-fill" id="cpu-bar" style="width:35%">35%</div>
    </div>
    
    <button class="btn" id="sim">SIMULATE TRAFFIC SURGE</button>
    <p id="msg">Click to see auto-scaling!</p>
    
    <script>
        let s=2, c=35, i;
        function u(){ 
            document.getElementById('count').textContent=s;
            document.getElementById('cpu-val').textContent=c;
            document.getElementById('cpu-bar').style.width=c+'%';
            document.getElementById('cpu-bar').textContent=c+'%';
            let d=document.getElementById('servers').children;
            for(let j=0;j<d.length;j++) d[j].className=j<s?'server active':'server';
        }
        document.getElementById('sim').onclick=function(){
            this.disabled=true;
            document.getElementById('msg').textContent='Traffic surging!';
            let st=0;
            i=setInterval(function(){
                st++; c=Math.min(85,35+st*5); u();
                if(c>=70&&s<4){ s++; u(); document.getElementById('msg').textContent='Server '+s+' launched!'; }
                if(st>=15){ clearInterval(i); this.disabled=false; document.getElementById('msg').textContent='Done!'; 
                    setTimeout(function(){ c=35; s=2; u(); document.getElementById('msg').textContent='Ready.'; }, 5000);
                }
            }, 600);
        };
        u();
    </script>
</body>
</html>
HTML

cat > /var/www/html/health <<< "OK"
cat > /etc/nginx/sites-available/default <<< "server { listen 80; root /var/www/html; index index.html; location /health { return 200 'OK\n'; } }"
systemctl enable nginx && systemctl restart nginx
